
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["137112412989"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_iam_role" "ec2_ssm" {
  name = "nextcloud-ec2-ssm-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "nextcloud-ec2-instance-profile"
  role = aws_iam_role.ec2_ssm.name
}

resource "aws_launch_template" "nextcloud" {
  name_prefix            = "nextcloud-lt-"
  image_id               = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.ec2.ids]

  iam_instance_profile { name = aws_iam_instance_profile.ec2_profile.name }

  user_data = base64encode(
    templatefile("${path.module}/user-data.sh.tftpl", {
      db_host = aws_db_instance.this.address
      db_name = var.db_name
      db_user = var.db_username
      db_pass = var.db_password
      efs_id  = aws_efs_file_system.nextcloud.id
    })
  )

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = "nextcloud-ec2" })
  }
}

resource "aws_autoscaling_group" "nextcloud" {
  name                      = "nextcloud-asg"
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier       = module.vpc.private_subnets
  health_check_type         = "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.nextcloud.id
    version = "$Latest"
  }

  target_group_arns = module.alb.target_group_arns

  tag {
    key                 = "Name"
    value               = "nextcloud-instance"
    propagate_at_launch = true
  }

  lifecycle { create_before_destroy = true }
}
