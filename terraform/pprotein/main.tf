data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_vpc" "monitor" {
  cidr_block           = "10.80.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "isucon-pprotein" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.monitor.id
  cidr_block              = "10.80.1.0/24"
  map_public_ip_on_launch = false

  tags = { Name = "isucon-pprotein-public" }
}

resource "aws_internet_gateway" "monitor" {
  vpc_id = aws_vpc.monitor.id

  tags = { Name = "isucon-pprotein" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.monitor.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.monitor.id
  }

  tags = { Name = "isucon-pprotein-public" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "monitor" {
  name        = "isucon-pprotein"
  description = "SSH access to the pprotein monitoring server"
  vpc_id      = aws_vpc.monitor.id

  ingress {
    description = "SSH from the team"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_ingress_cidrs
  }

  egress {
    description = "Outbound access including SSH to competition servers"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "isucon-pprotein" }
}

resource "aws_instance" "monitor" {
  ami                         = data.aws_ssm_parameter.al2023_ami.value
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.monitor.id]
  associate_public_ip_address = false

  tags = { Name = "isucon-pprotein" }
}

resource "aws_eip" "monitor" {
  domain   = "vpc"
  instance = aws_instance.monitor.id

  depends_on = [aws_internet_gateway.monitor]

  tags = { Name = "isucon-pprotein" }
}
