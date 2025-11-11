# SG do ALB
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

# SG da aplicação (EC2)
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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "nextcloud-ec2-sg" })
}

# SG do EFS
resource "aws_security_group" "efs_sg" {
  name        = "nextcloud-efs-sg"
  description = "Security Group for EFS"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "nextcloud-efs-sg" })
}

# Regra *separada* de NFS (sem ingress/egress/tags aqui!)
resource "aws_vpc_security_group_ingress_rule" "efs_nfs_from_app" {
  security_group_id            = aws_security_group.efs_sg.id
  referenced_security_group_id = aws_security_group.ec2_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 2049
  to_port                      = 2049
  description                  = "Allow NFS from EC2 SG to EFS SG"
}

# SG do RDS
resource "aws_security_group" "rds_sg" {
  name        = "nc-rds-sg"
  description = "Permite acesso ao PostgreSQL (5432) a partir da aplicação"
  vpc_id      = module.vpc.vpc_id

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

  tags = merge(var.tags, { Name = "nc-rds-sg", Backup = "true" })
}
 'https://github.com/apduartte/nextcloud.git'

