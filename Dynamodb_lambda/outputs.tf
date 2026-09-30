output "dynamodb_table_name" {
  description = "Name of the DynamoDB table used by the orders workload"
  value       = aws_dynamodb_table.orders.name
}

output "lambda_function_name" {
  description = "Name of the Lambda CRUD function"
  value       = aws_lambda_function.orders_crud.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda CRUD function"
  value       = aws_lambda_function.orders_crud.arn
}
