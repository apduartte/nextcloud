module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "9.8.0"

  name               = "nextcloud-alb"
  load_balancer_type = "application"

  vpc_id         = module.vpc.vpc_id
  subnets        = module.vpc.public_subnets
  security_groups = [aws_security_group.alb.id]

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = "nxt"
      }
    }
  }

  target_groups = {
    nxt = {
      name_prefix = "nxt-"
      protocol    = "HTTP"
      port        = 80
      target_type = "instance"
      health_check = {
        path = "/"
        port = "80"
      }
    }
  }

  tags = var.tags
}
