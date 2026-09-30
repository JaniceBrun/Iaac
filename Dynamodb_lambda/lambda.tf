data "archive_file" "orders_crud" {
  type        = "zip"
  source_file = "${path.module}/lambda/lambda_function.py"
  output_path = "${path.module}/.build/orders-crud.zip"
}

resource "aws_lambda_function" "orders_crud" {
  function_name    = var.lambda_function_name
  runtime          = var.lambda_runtime
  handler          = var.lambda_handler
  role             = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.lab_role_name}"
  filename         = data.archive_file.orders_crud.output_path
  source_code_hash = data.archive_file.orders_crud.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.orders.name
    }
  }
}
