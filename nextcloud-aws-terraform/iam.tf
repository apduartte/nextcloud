############################################
# IAM - Role e Instance Profile para EC2
############################################

# Role assumida pelas instâncias EC2 (Nextcloud)
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role-vm"
  path = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-ec2-role"
  })
}

############################################
# Anexos de políticas gerenciadas (Managed Policies)
############################################

# Permite usar AWS Systems Manager (SSM) para acessar a EC2
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# OPCIONAL: se você for usar CloudWatch Agent para logs/métricas na instância
# descomente se precisar.
#
# resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
#   role       = aws_iam_role.ec2_role.name
#   policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
# }

############################################
# Instance Profile usado pelo Launch Template
############################################

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile-vm"
  role = aws_iam_role.ec2_role.name
}
