variable "aws_region" {
  description = "Región de AWS"
  default     = "us-east-1"
}

variable "ecr_repository_name" {
  description = "Nombre del repositorio ECR"
  default     = "my-ecr-devops-test"
}

variable "ec2_instance_type" {
  description = "Tipo de instancia EC2"
  default     = "t2.micro"  # Dentro de la capa gratuita
}

variable "ec2_ami_id" {
  description = "ID de la AMI"
  default     = "ami-0c02fb55956c7d316"  # AMI de Amazon Linux 2 (gratuita)
}
