############################################
# EFS - Sistema de arquivos compartilhado
############################################

resource "aws_efs_file_system" "this" {
  creation_token   = "${var.project_name}-efs"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = true

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-efs"
  })
}

############################################
# EFS Mount Targets - 1 por subnet privada
############################################

resource "aws_efs_mount_target" "this" {
  for_each = toset(module.vpc.private_subnets)

  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs.id]
}
