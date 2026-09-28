terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

# ── DynamoDB ────────────────────────────────────────────────────────────────

resource "aws_dynamodb_table" "users" {
  name         = "lab02-users"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"

  attribute {
    name = "userId"
    type = "S"
  }
}

# ── Lambda packages ─────────────────────────────────────────────────────────

data "archive_file" "crud_user" {
  type        = "zip"
  source_file = "${path.module}/lambda/crud_user/handler.py"
  output_path = "${path.module}/.build/crud_user.zip"
}

data "archive_file" "simple_authorizer" {
  type        = "zip"
  source_file = "${path.module}/lambda/simple_authorizer/handler.py"
  output_path = "${path.module}/.build/simple_authorizer.zip"
}

# ── Lambda: crud-user ────────────────────────────────────────────────────────

resource "aws_lambda_function" "crud_user" {
  function_name    = "crud-user"
  runtime          = "python3.12"
  handler          = "handler.handler"
  role             = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
  filename         = data.archive_file.crud_user.output_path
  source_code_hash = data.archive_file.crud_user.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.users.name
    }
  }
}

# ── Lambda: simple-authorizer ────────────────────────────────────────────────

resource "aws_lambda_function" "simple_authorizer" {
  function_name    = "simple-authorizer"
  runtime          = "python3.12"
  handler          = "handler.handler"
  role             = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
  filename         = data.archive_file.simple_authorizer.output_path
  source_code_hash = data.archive_file.simple_authorizer.output_base64sha256

  environment {
    variables = {
      AUTH_TOKEN = var.auth_token
    }
  }
}

# ── API Gateway ──────────────────────────────────────────────────────────────

resource "aws_api_gateway_rest_api" "api" {
  name = "lab02-api"
}

resource "aws_api_gateway_authorizer" "token_auth" {
  name                   = "simple-authorizer"
  rest_api_id            = aws_api_gateway_rest_api.api.id
  authorizer_uri         = aws_lambda_function.simple_authorizer.invoke_arn
  type                   = "TOKEN"
  identity_source        = "method.request.header.Authorization"
  authorizer_result_ttl_in_seconds = 0
}

resource "aws_lambda_permission" "apigw_authorizer" {
  statement_id  = "AllowAPIGWAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.simple_authorizer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "apigw_crud" {
  statement_id  = "AllowAPIGWCrud"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.crud_user.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

# /users
resource "aws_api_gateway_resource" "users" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "users"
}

# /users/{id}
resource "aws_api_gateway_resource" "user_id" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.users.id
  path_part   = "{id}"
}

locals {
  routes = {
    list   = { resource = aws_api_gateway_resource.users.id,   method = "GET" }
    create = { resource = aws_api_gateway_resource.users.id,   method = "POST" }
    get    = { resource = aws_api_gateway_resource.user_id.id, method = "GET" }
    update = { resource = aws_api_gateway_resource.user_id.id, method = "PUT" }
    delete = { resource = aws_api_gateway_resource.user_id.id, method = "DELETE" }
  }
}

resource "aws_api_gateway_method" "methods" {
  for_each      = local.routes
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = each.value.resource
  http_method   = each.value.method
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.token_auth.id
}

resource "aws_api_gateway_integration" "integrations" {
  for_each                = local.routes
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = each.value.resource
  http_method             = aws_api_gateway_method.methods[each.key].http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.crud_user.invoke_arn
}

resource "aws_api_gateway_deployment" "deploy" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_method.methods,
      aws_api_gateway_integration.integrations,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_api_gateway_integration.integrations]
}

resource "aws_api_gateway_stage" "v1" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.deploy.id
  stage_name    = "v1"
}
