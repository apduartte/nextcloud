
## asg_ec2.tf (Launch Template + ASG)
```hcl
data "aws_subnet" "private_a" {
  id = module.vpc.private_subnets[0]
}

data "aws_subnet" "private_b" {
  id = module.vpc.private_subnets[1]
}

# DNS fácil do EFS (regional)
locals {
  efs_dns = "${aws_efs_file_system.this.id}.efs.${var.region}.amazonaws.com"
}

data "template_file" "user_data" {
  template = file("${path.module}/user-data.sh")
  vars = {
    efs_dns         = local.efs_dns
    db_host         = aws_db_instance.this.address
    db_name         = var.db_name
    db_user         = var.db_username
    db_pass         = var.db_password
    trusted_domains = var.trusted_domains
  }
}

resource "aws_launch_template" "this" {
  name_prefix   = "${var.project_name}-lt-"
  image_id      = data.aws_ami.al2023.id
  instance_type = var.instance_type
  key_name      = var.key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  user_data = base64encode(data.template_file.user_data.rendered)

  network_interfaces {
    security_groups = [aws_security_group.ec2.id]
  }

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["137112412989"] # Amazon

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

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

  target_group_arns = [aws_lb_target_group.this.arn]

  tag {
    key                 = "Name"
    value               = "${var.project_name}-ec2"
    propagate_at_launch = true
  }
}
```
