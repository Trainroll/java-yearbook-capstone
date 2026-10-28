
output "vpc_id" {
  description = "ID of the capstone VPC"
  value       = aws_vpc.capstone.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "app_instance_id" {
  description = "ID of the application EC2 instance"
  value       = aws_instance.app.id
}

output "app_public_ip" {
  description = "Public IP of the application server"
  value       = aws_eip.app.public_ip
}

output "app_security_group_id" {
  description = "Application security group ID"
  value       = aws_security_group.app.id
}


output "ansible_inventory_path" {
  description = "Local path to the generated Ansible inventory"
  value       = local_sensitive_file.ansible_inventory.filename
  sensitive   = true
}

output "app_ssh_command" {
  description = "SSH command for the application server"
  value       = "ssh -i ${var.ssh_private_key_path} ec2-user@${aws_eip.app.public_ip}"
}
