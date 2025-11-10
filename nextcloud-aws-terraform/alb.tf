
resource "aws_lb" "nextcloud_alb" {
  name               = "nextcloud-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = module.vpc.public_subnets

  enable_deletion_protection = false

  tags = var.tags
}

resource "aws_lb_target_group" "nextcloud_tg" {
  name_prefix = "nxt-"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = module.vpc.vpc_id

  health_check {
    path                = "/"
    port                = "80"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = var.tags
}

resource "aws_lb_listener" "nextcloud_listener" {
  load_balancer_arn = aws_lb.nextcloud_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nextcloud_tg.arn
  }
}

output "alb_dns_name" {
  value = aws_lb.nextcloud_alb.dns_name
}
