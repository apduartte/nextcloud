############################################################
# EFS – Security Group (compartilhado entre instâncias do ASG)
############################################################
resource "aws_security_group" "efs" {
  name        = "nc-efs-sg"
  description = "Allow NFS (2049) from App SG and/or VPC CIDR"
  vpc_id      = module.vpc.vpc_id

  tags = merge(var.tags, {
    Name   = "nc-efs-sg"
    Backup = "true"
  })
}

resource "aws_vpc_security_group_egress_rule" "efs_all_out" {
  security_group_id = aws_security_group.efs.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "efs_from_app_sg" {
  security_group_id            = aws_security_group.efs.id
  referenced_security_group_id = var.app_sg_id
  from_port                    = 2049
  to_port                      = 2049
  ip_protocol                  = "tcp"
  description                  = "NFS from App SG"
}

resource "aws_vpc_security_group_ingress_rule" "efs_from_vpc" {
  security_group_id = aws_security_group.efs.id
  cidr_ipv4         = var.vpc_cidr
  from_port         = 2049
  to_port           = 2049
  ip_protocol       = "tcp"
  description       = "NFS from VPC CIDR (fallback)"
}

############################################
# RDS PostgreSQL (Multi-AZ)
############################################
resource "aws_db_subnet_group" "this" {
  name       = "nc-db-subnets"
  subnet_ids = module.vpc.private_subnets

  tags = var.tags
}

resource "aws_security_group" "rds" {
  name   = "nc-rds-sg"
  vpc_id = module.vpc.vpc_id

  tags = merge(var.tags, {
    Name = "nc-rds-sg"
  })
}

resource "aws_vpc_security_group_egress_rule" "rds_all_out" {
  security_group_id = aws_security_group.rds.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_app_sg" {
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = var.app_sg_id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  description                  = "PostgreSQL from App SG"
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_vpc" {
  security_group_id = aws_security_group.rds.id
  cidr_ipv4         = var.vpc_cidr
  from_port         = 5432
  to_port           = 5432
  ip_protocol       = "tcp"
  description       = "PostgreSQL from VPC CIDR (fallback)"
}

resource "aws_db_instance" "this" {
  identifier              = "nc-postgres"
  engine                  = "postgres"
  engine_version          = var.db_engine_version
  instance_class          = var.db_instance_class
  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password
  multi_az                = true
  allocated_storage       = 50
  max_allocated_storage   = 200
  storage_encrypted       = true
  publicly_accessible     = false
  backup_retention_period = 7
  backup_window           = "07:00-09:00"
  maintenance_window      = "Sun:03:00-Sun:04:00"
  deletion_protection     = true
  skip_final_snapshot     = false
  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = [aws_security_group.rds.id]

  tags = merge(var.tags, {
    Name   = "nc-postgres"
    Backup = "true"
  })
}

############################################
# SNS – tópico para alertas
############################################
resource "aws_sns_topic" "alerts" {
  name = "nc-alerts"
  tags = var.tags
}

############################################################
# ACM (us-east-1) com validação DNS em Route53 (para CloudFront)
############################################################
resource "aws_acm_certificate" "cf" {
  provider          = aws.use1
  domain_name       = var.domain_name
  validation_method = "DNS"
  tags              = var.tags
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cf.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = var.hosted_zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

resource "aws_acm_certificate_validation" "cf" {
  provider                = aws.use1
  certificate_arn         = aws_acm_certificate.cf.arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
}

############################################
# WAFv2 (global / us-east-1) para CloudFront
############################################
resource "aws_wafv2_web_acl" "cf" {
  provider = aws.use1
  name     = "nc-cf-waf"
  scope    = "CLOUDFRONT"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "nc-cf-waf"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "common"
      sampled_requests_enabled   = true
    }
  }
}

############################################################
# AWS Backup – captura por tag Backup = true (EFS/RDS)
############################################################
resource "aws_backup_vault" "this" {
  name = "nc-backup-vault"
  tags = var.tags
}

resource "aws_backup_plan" "this" {
  name = "nc-backup-plan"

  rule {
    rule_name         = "daily-7d"
    target_vault_name = aws_backup_vault.this.name
    schedule          = "cron(0 3 * * ? *)"

    lifecycle {
      delete_after = 7
    }
  }
}

data "aws_iam_role" "backup" {
  name = "AWSBackupDefaultServiceRole"
}

resource "aws_backup_selection" "by_tag" {
  name         = "tag-selection"
  iam_role_arn = data.aws_iam_role.backup.arn
  plan_id      = aws_backup_plan.this.id

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "Backup"
    value = "true"
  }
}

# Guarda de destruição fora do bloco (corrigido)
resource "null_resource" "destroy_guard" {
  count = var.enable_destroy ? 0 : 1

  lifecycle {
    prevent_destroy = true
  }

  provisioner "local-exec" {
    command = "echo 'Destruição bloqueada. Altere enable_destroy para true se tiver certeza.'"
  }
}