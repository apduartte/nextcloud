## efs.tf
resource "aws_efs_file_system" "this" {
  creation_token   = "${var.project_name}-efs"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name = "${var.project_name}-efs"
  }
}

resource "aws_efs_mount_target" "a" {
  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = module.vpc.private_subnets[0]
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_mount_target" "b" {
  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = module.vpc.private_subnets[1]
  security_groups = [aws_security_group.efs.id]
}


