############################################
# Auto Scaling - EC2 para Nextcloud
############################################

# AMI Amazon Linux 2023 mais recente (x86_64)
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["137112412989"] # Amazon

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

############################################
# Locais - DNS do EFS e user_data
############################################

# DNS regional do EFS baseado no ID do filesystem
locals {
  efs_dns = "${aws_efs_file_system.this.id}.efs.${var.region}.amazonaws.com"

  # Renderiza o script de user_data com variáveis da app
  user_data = templatefile("${path.module}/user-data.sh", {
    efs_dns         = local.efs_dns
    db_host         = aws_db_instance.this.address
    db_name         = var.db_name
    db_user         = var.db_username
    db_pass         = var.db_password
    trusted_domains = var.trusted_domains
  })
}

############################################
# Launch Template - configuração das instâncias EC2
############################################

resource "aws_launch_template" "this" {
  name_prefix   = "${var.project_name}-lt-"
  image_id      = data.aws_ami.al2023.id
  instance_type = var.instance_type

  # Só define key pair se informado (evita erro com string vazia)
  key_name = var.key_name != "" ? var.key_name : null

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  # Script de inicialização da instância (Nextcloud, EFS, etc)
  user_data = base64encode(local.user_data)

  # Interface de rede padrão (subnets vêm do ASG)
  network_interfaces {
    security_groups             = [aws_security_group.ec2.id]
    associate_public_ip_address = false
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-lt"
  })
}

############################################
# Auto Scaling Group - EC2 atrás do ALB
############################################

resource "aws_autoscaling_group" "this" {
  name                      = "${var.project_name}-asg"
  min_size                  = 1
  max_size                  = 1
  desired_capacity          = 1
  vpc_zone_identifier       = module.vpc.private_subnets
  health_check_type         = "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  # Envia as instâncias para o Target Group do ALB
  target_group_arns = [aws_lb_target_group.this.arn]

  # Tag padrão Name nas instâncias
  tag {
    key                 = "Name"
    value               = "${var.project_name}-ec2"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
