
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "9.8.0"

  name               = "nextcloud-alb"
  load_balancer_type = "application"
  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.public_subnets
  security_groups    = [aws_security_group.alb.id]

  listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      default_action = {
      type = "forward"
      target_group_index = 0
     }
    }
  ]

  target_groups = [
    {
      name_prefix      = "nxt-"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
      health_check     = { path = "/", port = "80" }
    }
  ]

  tags = var.tags
}
