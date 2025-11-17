############################################
# Security Group - Application Load Balancer
############################################

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Security Group do Application Load Balancer"
  vpc_id      = module.vpc.vpc_id

  # HTTP da internet
  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS condicional, conforme var.enable_https
  dynamic "ingress" {
    for_each = var.enable_https ? [1] : []
    content {
      description = "HTTPS from Internet"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # Saída liberada (para health checks, DNS, updates, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-alb-sg"
  })
}

############################################
# Security Group - EC2 (ASG Nextcloud)
############################################

resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-ec2-sg"
  description = "Security Group das instâncias EC2 (ASG Nextcloud)"
  vpc_id      = module.vpc.vpc_id

  # Recebe tráfego HTTP apenas do ALB
  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Saída liberada (acesso à internet via NAT, RDS, EFS, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-ec2-sg"
  })
}

############################################
# Security Group - RDS (PostgreSQL)
# Regras de entrada/saída são definidas
# em aws_vpc_security_group_ingress_rule / egress_rule
############################################

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Security Group do banco de dados PostgreSQL (RDS)"
  vpc_id      = module.vpc.vpc_id

  tags = merge(var.tags, {
    Name = "${var.project_name}-rds-sg"
  })
}

############################################
# Security Group - EFS
# Regras de entrada/saída são definidas
# em aws_vpc_security_group_ingress_rule / egress_rule
############################################

resource "aws_security_group" "efs" {
  name        = "${var.project_name}-efs-sg"
  description = "Security Group do EFS (NFS)"
  vpc_id      = module.vpc.vpc_id

  tags = merge(var.tags, {
    Name = "${var.project_name}-efs-sg"
  })
}
