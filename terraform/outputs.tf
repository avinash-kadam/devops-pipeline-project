output "instance_public_ip" {
  description = "Public IP of the EC2 instance — plug this into ansible/inventory/hosts.ini"
  value       = aws_instance.app_server.public_ip
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.app_server.id
}

output "app_url" {
  description = "URL to access the deployed app"
  value       = "http://${aws_instance.app_server.public_ip}"
}
