variable "ami_id" {
  description = "Amazon Linux 2023 AMI ID (region-specific)"
  type        = string
  default     = "ami-05572e392e4e15d44"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Name of the existing EC2 key pair (demo-key)"
  type        = string
  default     = "demo-key"
}

