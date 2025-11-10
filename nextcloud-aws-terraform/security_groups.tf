#############################
# SG do Load Balancer (ALB) #
#############################
resource "aws_security_group" "alb_sg" {
  name        = "nextcloud-alb-sg"
  description = "Permite HTTP/HTTPS do público para o ALB"
  vpc_id      = module.vpc.vpc_id

  tags = merge(var.tags, { Name = "nextcloud-alb-sg" })
}

# Ingress 80 e 443 do público
resource "aws_vpc_security_group_ingress_rule" "alb_http_80" {
  security_group_id = aws_security_group.alb_sg.id
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
  description       = "HTTP público"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https_443" {
  security_group_id = aws_security_group.alb_sg.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
  description       = "HTTPS público"
}

# Egress geral do ALB
resource "aws_vpc_security_group_egress_rule" "alb_all_out" {
  security_group_id = aws_security_group.alb_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Saída liberada"
}

############################
# SG das instâncias (EC2)  #
############################
resource "aws_security_group" "ec2_sg" {
  name        = "nextcloud-ec2-sg"
  description = "Recebe HTTP do ALB e permite saída geral"
  vpc_id      = module.vpc.vpc_id

  tags = merge(var.tags, { Name = "nextcloud-ec2-sg" })
}

# Ingress 80 somente a partir do SG do ALB
resource "aws_vpc_security_group_ingress_rule" "ec2_http_from_alb" {
  security_group_id            = aws_security_group.ec2_sg.id
  referenced_security_group_id = aws_security_group.alb_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
  description                  = "HTTP vindo do ALB"
}

# Egress geral para a internet (inclui acesso ao RDS/EFS, updates etc.)
resource "aws_vpc_security_group_egress_rule" "ec2_all_out" {
  security_group_id = aws_security_group.ec2_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Saída liberada"
}

########################
# SG do banco (RDS)    #
########################
resource "aws_security_group" "rds_sg" {
  name        = "nc-rds-sg"
  description = "Acesso ao PostgreSQL (5432) a partir da aplicação"
  vpc_id      = module.vpc.vpc_id

  tags = merge(var.tags, {
    Name   = "nc-rds-sg"
    Backup = "true"
  })
}

# Ingress 5432 somente a partir do SG das EC2 (aplicação)
resource "aws_vpc_security_group_ingress_rule" "rds_pg_from_app" {
  security_group_id            = aws_security_group.rds_sg.id
  referenced_security_group_id = aws_security_group.ec2_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  description                  = "PostgreSQL a partir da app (EC2)"
}
