############################################
# Application Load Balancer (ALB)
############################################

resource "aws_lb" "this" {
  name = "${var.project_name}-alb-vm"

  load_balancer_type = "application"
  internal           = false

  security_groups = [aws_security_group.alb.id]
  subnets         = module.vpc.public_subnets

  enable_deletion_protection = false
  idle_timeout                     = 60
  enable_cross_zone_load_balancing = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-alb"
  })
}

############################################
# Target Group da aplicação (Nextcloud)
############################################

resource "aws_lb_target_group" "this" {
  name     = "${var.project_name}-tg-vm"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    protocol            = "HTTP"
    path                = "/status.php"
    matcher             = "200-399"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    interval            = 30
    timeout             = 5
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-tg-vm"
  })
}

############################################
# Listener HTTP (80) – quando NÃO usa HTTPS
# Faz forward direto para o Target Group
############################################

resource "aws_lb_listener" "http" {
  count             = var.enable_https ? 0 : 1
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

############################################
# Listener HTTP (80) – quando usa HTTPS
# Redireciona 80 -> 443
############################################

resource "aws_lb_listener" "http_redirect" {
  count             = var.enable_https ? 1 : 0
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      protocol    = "HTTPS"
      port        = "443"
      status_code = "HTTP_301"
    }
  }
}

############################################
# Listener HTTPS (443) – ALB termina o TLS
############################################

resource "aws_lb_listener" "https" {
  count             = var.enable_https ? 1 : 0
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}
