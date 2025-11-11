# efs.tf
resource "aws_efs_file_system" "nextcloud" {
  encrypted        = true
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  tags             = merge(var.tags, { Name = "nextcloud-efs" })
}

resource "aws_efs_mount_target" "nextcloud" {
  for_each        = toset(module.vpc.private_subnets)
  file_system_id  = aws_efs_file_system.nextcloud.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs_sg.id]  # ver item 2
}
 
