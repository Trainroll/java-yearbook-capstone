
resource "aws_vpc" "capstone" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "${var.project_name}-vpc"
    Project = var.project_name
  }
}

resource "aws_internet_gateway" "capstone" {
  vpc_id = aws_vpc.capstone.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.capstone.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.capstone.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.capstone.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "app" {
  name        = "${var.project_name}-app-sg"
  description = "Security group for capstone application server"
  vpc_id      = aws_vpc.capstone.id

  ingress {
    description = "SSH administration from trusted IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  ingress {
    description = "Portfolio application"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Outbound connectivity"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-app-sg"
  }
}


resource "aws_instance" "app" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.app.id]
  associate_public_ip_address = true
  key_name                    = var.key_name

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }
  tags = {
    Name    = "${var.project_name}-app-server"
    Project = var.project_name
    Role    = "application"
  }
}

resource "aws_eip" "app" {
  domain = "vpc"

  tags = {
    Name    = "${var.project_name}-app-eip"
    Project = var.project_name
  }
}

resource "aws_eip_association" "app" {
  instance_id   = aws_instance.app.id
  allocation_id = aws_eip.app.id
}

resource "local_sensitive_file" "ansible_inventory" {
  filename        = "${path.module}/inventory.ini"
  file_permission = "600"

  content = <<-EOT
    [app]
    ${aws_eip.app.public_ip} ansible_user=ec2-user ansible_ssh_private_key_file=${var.ssh_private_key_path} ansible_python_interpreter=/usr/bin/python3
    EOT

  depends_on = [aws_instance.app]

}
