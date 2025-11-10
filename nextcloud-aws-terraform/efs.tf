
resource "aws_efs_file_system" "nextcloud" {
  creation_token   = "nextcloud-efs"
  performance_mode = "generalPurpose"
  throughput_mode  = "elastic"
  encrypted        = true
  tags             = merge(var.tags, { Name = "nextcloud-efs" })
}

resource "aws_efs_mount_target" "private_1a" {
  file_system_id  = aws_efs_file_system.nextcloud.id
  subnet_id       = module.vpc.private_subnets[0]
  security_groups = [aws_security_group.ec2_sg]
}

resource "aws_efs_mount_target" "private_1b" {
  file_system_id  = aws_efs_file_system.nextcloud.id
  subnet_id       = module.vpc.private_subnets[1]
  security_groups = [aws_security_group.ec2_sg]
}
 