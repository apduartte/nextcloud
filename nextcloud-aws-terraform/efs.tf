# efs.tf
resource "aws_efs_file_system" "main" {
  creation_token = "nextcloud-efs"
  encrypted      = true

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = merge(var.tags, { Name = "nextcloud-efs" })
}
 