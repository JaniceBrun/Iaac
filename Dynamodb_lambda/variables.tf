variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "table_name" {
  description = "Name of the DynamoDB table"
  type        = string
  default     = "prova01-orders"
}

variable "lambda_function_name" {
  description = "Name of the Lambda CRUD function"
  type        = string
  default     = "orders-crud"
}

variable "lambda_runtime" {
  description = "Runtime for the Lambda function"
  type        = string
  default     = "python3.12"
}

variable "lambda_handler" {
  description = "Handler entry point for the Lambda function"
  type        = string
  default     = "lambda_function.lambda_handler"
}

variable "lab_role_name" {
  description = "IAM role used by the Lambda function"
  type        = string
  default     = "LabRole"
}

variable "sample_orders" {
  description = "Initial content inserted into the DynamoDB table"
  type = list(object({
    customer_id = string
    order_date  = string
    product     = string
    quantity    = number
    total       = number
  }))
  default = [
    {
      customer_id = "C001"
      order_date  = "2025-01-15"
      product     = "Laptop"
      quantity    = 1
      total       = 999.99
    },
    {
      customer_id = "C001"
      order_date  = "2025-02-20"
      product     = "Mouse"
      quantity    = 2
      total       = 49.98
    },
    {
      customer_id = "C001"
      order_date  = "2025-03-10"
      product     = "Keyboard"
      quantity    = 1
      total       = 79.99
    },
    {
      customer_id = "C002"
      order_date  = "2025-01-22"
      product     = "Monitor"
      quantity    = 1
      total       = 349.99
    },
    {
      customer_id = "C002"
      order_date  = "2025-03-05"
      product     = "Webcam"
      quantity    = 1
      total       = 89.99
    }
  ]
}
