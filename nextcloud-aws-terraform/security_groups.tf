# Security Group para o Load Balancer (ALB)
resource "aws_security_group" "alb_sg" {
  name        = "nextcloud-alb-sg"
  description = "Permite HTTP/HTTPS"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "nextcloud-alb-sg" })
}

# Security Group para instâncias EC2
resource "aws_security_group" "ec2_sg" {
  name        = "nextcloud-ec2-sg"
  description = "Permite HTTP do ALB e NFS + saída geral"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "nextcloud-ec2-sg" })
}

# Security Group para o RDS
resource "aws_security_group" "rds_sg" {
  name        = "nc-rds-sg"
  description = "Permite acesso ao PostgreSQL (porta 5432) a partir da aplicação"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name   = "nc-rds-sg"
    Backup = "true"
  })
}