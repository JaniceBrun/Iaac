output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.demo_web_01.id
}

output "public_ip" {
  description = "Public IP of the EC2 instance (use for SSH)"
  value       = aws_instance.demo_web_01.public_ip
}
