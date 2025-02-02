# VPC y componentes (gratuitos)
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"  # Usa una zona dentro de tu región
  map_public_ip_on_launch = true  # <-- Añade esta línea

}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group (gratuito)
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg"
  description = "Permitir HTTP y SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["181.42.131.201/32"]  # Restringe esto a tu IP en producción
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "my_key" {
  key_name   = "my-ec2-key"
  public_key = file("~/.ssh/aws-ec2-key.pub")  # Ruta a tu clave pública local
}

# EC2 t2.micro (Free Tier)
resource "aws_instance" "my_instance" {
  ami           = var.ec2_ami_id
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  subnet_id              = aws_subnet.public.id

  key_name = aws_key_pair.my_key.key_name  

  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install docker -y
    sudo service docker start
    sudo usermod -a -G docker ec2-user
    sudo systemctl enable docker
  EOF

  tags = {
    Name = "my-ec2-instance"
  }
}

# ECR (Free Tier hasta 500 MB/mes)
resource "aws_ecr_repository" "my_repo" {
  name = "my-ecr-repo"
}