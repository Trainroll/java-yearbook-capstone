
variable "aws_region" {
  description = "AWS region for the capstone"
  type        = string
}

variable "project_name" {
  description = "Prefix for AWS resource names"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR range for the custom VPC"
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR range for the public subnet"
  type        = string
}

variable "availability_zone" {
  description = "Availability zone for the public subnet"
  type        = string
}

variable "ami_id" {
  description = "Valid Linux AMI ID in the selected region"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "admin_cidr" {
  description = "Trusted administrator CIDR for SSH access"
  type        = string

  validation {
    condition     = can(cidrnetmask(var.admin_cidr))
    error_message = "admin_cidr must be a valid IPv4 CIDR range, such as 203.0.113.10/32."
  }
}

variable "key_name" {
  description = "Name of the existing EC2 keypair in the selected region"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Local filesystem path to the SSH private key used by Ansible"
  type        = string
}
