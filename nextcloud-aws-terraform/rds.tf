# Subnet Group para o banco de dados RDS
resource "aws_db_subnet_group" "nc_db_subnet_group" {
  name       = "nc-db-subnets"
  subnet_ids = var.private_subnet_ids

  tags = var.tags
}

# Instância RDS para o banco PostgreSQL do Nextcloud
resource "aws_db_instance" "nextcloud_db_instance" {
  identifier              = "nextcloud-db"
  engine                  = "postgres"
  engine_version          = var.db_engine_version
  instance_class          = var.db_instance_class
  allocated_storage       = var.db_allocated_gb
  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.nc_db_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  publicly_accessible     = false
  skip_final_snapshot     = true
  deletion_protection     = false
  apply_immediately       = true
  storage_encrypted       = true

  tags = merge(var.tags, { Name = "nextcloud-db" })
}