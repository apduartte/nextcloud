############################################
# RDS PostgreSQL - Subnet Group
############################################

resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-db-subnets-vm"
  subnet_ids = module.vpc.private_subnets

  tags = merge(var.tags, {
    Name = "${var.project_name}-db-subnet-group"
  })
}

############################################
# RDS PostgreSQL - Instância
############################################

resource "aws_db_instance" "this" {
  identifier = "${var.project_name}-db-vm"

  # Engine
  engine         = "postgres"
  engine_version = "16"

  # Capacidade
  instance_class    = var.db_instance_class    # ex: "db.t3.micro"
  allocated_storage = var.db_allocated_storage # ex: 20
  storage_type      = "gp3"

  # Credenciais e banco
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = 5432

  # Rede
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.this.name
  publicly_accessible    = false
  multi_az               = false # pode virar variável depois, se quiser

  # Backup e ciclo de vida
  backup_retention_period    = 1 # 1 dia (mínimo). Pode aumentar p/ 7 se quiser mais segurança.
  delete_automated_backups   = true
  copy_tags_to_snapshot      = true
  skip_final_snapshot        = true
  deletion_protection        = var.enable_destroy ? false : true
  auto_minor_version_upgrade = true
  apply_immediately          = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-db-vm"
  })
}
