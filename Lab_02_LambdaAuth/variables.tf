variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "auth_token" {
  description = "Bearer token validated by simple-authorizer"
  type        = string
  sensitive   = true
}
