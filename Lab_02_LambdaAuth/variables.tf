variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "lab_role_arn" {
  description = "ARN of the pre-existing LabRole (Learner Lab)"
  type        = string
}

variable "auth_token" {
  description = "Bearer token validated by simple-authorizer"
  type        = string
  sensitive   = true
}
