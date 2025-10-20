
resource "aws_db_subnet_group" "this" {
  name       = "nextcloud-rds-subnets"
  subnet_ids = module.vpc.private_subnets
  tags       = merge(var.tags, { Name = "nextcloud-rds-subnets" })
}

resource "aws_db_instance" "this" {
  identifier              = "nextcloud-db"
  engine                  = "postgres"
  engine_version          = var.db_engine_version
  instance_class          = var.db_instance_class
  allocated_storage       = var.db_allocated_gb
  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  publicly_accessible     = false
  skip_final_snapshot     = true
  deletion_protection     = false
  apply_immediately       = true
  storage_encrypted       = true
  tags = merge(var.tags, { Name = "nextcloud-db" })
}

