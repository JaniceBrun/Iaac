output "api_base_url" {
  description = "Base URL for the API (append /users)"
  value       = "${aws_api_gateway_stage.v1.invoke_url}/users"
}

output "crud_user_arn" {
  value = aws_lambda_function.crud_user.arn
}

output "simple_authorizer_arn" {
  value = aws_lambda_function.simple_authorizer.arn
}
