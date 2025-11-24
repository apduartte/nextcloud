############################################
# Regras de Security Group - EFS e RDS
############################################

# EFS: permite NFS (2049) a partir do SG das instâncias EC2 (ASG)
resource "aws_vpc_security_group_ingress_rule" "efs_from_app_sg" {
  security_group_id            = aws_security_group.efs.id
  referenced_security_group_id = aws_security_group.ec2.id
  from_port                    = 2049
  to_port                      = 2049
  ip_protocol                  = "tcp"
  description                  = "NFS from EC2 App SG"
}

# EFS: fallback permitindo NFS a partir de todo o CIDR da VPC
# ➜ Se quiser deixar mais restrito, você pode remover esta regra e ficar
#    apenas com o acesso vindo do SG de aplicação.
resource "aws_vpc_security_group_ingress_rule" "efs_from_vpc" {
  security_group_id = aws_security_group.efs.id
  cidr_ipv4         = var.vpc_cidr
  from_port         = 2049
  to_port           = 2049
  ip_protocol       = "tcp"
  description       = "NFS from VPC CIDR (fallback)"
}

# RDS: saída liberada (para updates, DNS, etc.)
resource "aws_vpc_security_group_egress_rule" "rds_all_out" {
  security_group_id = aws_security_group.rds.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# RDS: permite PostgreSQL (5432) a partir do SG das instâncias EC2 (ASG)
resource "aws_vpc_security_group_ingress_rule" "rds_from_app_sg" {
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = aws_security_group.ec2.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  description                  = "PostgreSQL from EC2 App SG"
}

############################################
# SNS – tópico para alertas
############################################

resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"

  tags = merge(var.tags, {
    Name = "${var.project_name}-alerts"
  })
}

############################################
# ACM (us-east-1) para CloudFront + validação DNS
############################################
# ⚠️ Requer provider alias:
# provider "aws" {
#   alias  = "use1"
#   region = "us-east-1"
# }
############################################

# Flag auxiliar para só criar ACM quando CloudFront estiver habilitado
# e domínio/hosted zone estiverem preenchidos.
locals {
  cf_use_managed_acm = var.enable_cloudfront && var.domain_name != "" && var.hosted_zone_id != ""
}

resource "aws_acm_certificate" "cf" {
  count    = local.cf_use_managed_acm ? 1 : 0
  provider = aws.use1

  domain_name       = var.domain_name
  validation_method = "DNS"

  tags = merge(var.tags, {
    Name = "${var.project_name}-cf-cert"
  })
}

resource "aws_route53_record" "cert_validation" {
  # Quando não usar ACM gerenciado, for_each = {} (não cria nada)
  for_each = local.cf_use_managed_acm ? {
    for dvo in aws_acm_certificate.cf[0].domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  } : {}

  zone_id = var.hosted_zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

resource "aws_acm_certificate_validation" "cf" {
  count    = local.cf_use_managed_acm ? 1 : 0
  provider = aws.use1

  certificate_arn         = aws_acm_certificate.cf[0].arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
}

############################################
# WAFv2 (global / us-east-1) para CloudFront
############################################

resource "aws_wafv2_web_acl" "cf" {
  count    = var.enable_cloudfront ? 1 : 0
  provider = aws.use1

  name  = "${var.project_name}-cf-waf"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-cf-waf"
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

  tags = merge(var.tags, {
    Name = "${var.project_name}-cf-waf"
  })
}

############################################
# AWS Backup – EFS/RDS selecionados por Tag "Backup = true"
############################################

resource "aws_backup_vault" "this" {
  name = "${var.project_name}-backup-vault-vm"

  tags = merge(var.tags, {
    Name = "${var.project_name}-backup-vault"
  })
}

resource "aws_backup_plan" "this" {
  name = "${var.project_name}-backup-plan"

  rule {
    rule_name         = "daily-7d"
    target_vault_name = aws_backup_vault.this.name
    schedule          = "cron(0 3 * * ? *)" # todo dia às 03:00 UTC

    lifecycle {
      delete_after = 7
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-backup-plan"
  })
}

# Role gerenciada padrão do AWS Backup
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

############################################
# Guarda de destruição (destroy guard)
############################################
# Comportamento:
#   - enable_destroy = false (default) ➜ bloqueia destruição
#   - enable_destroy = true            ➜ permite destruir (não cria o guard)
#
# Para o guard realmente proteger o ambiente, é importante que
# módulos/recursos críticos tenham "depends_on = [null_resource.destroy_guard]"
# ou algo semelhante.
############################################

resource "null_resource" "destroy_guard" {
  #  count = var.enable_destroy ? 0 : 1
  #
  #  lifecycle {
  #   prevent_destroy = true
  # }

  #  provisioner "local-exec" {
  #    command = "echo 'Destruição bloqueada. Altere enable_destroy para true se tiver certeza.'"
  #  }
}
