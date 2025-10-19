############################################
# Providers
############################################
provider "aws" {
  # region padrão do seu ambiente (ex.: us-east-1, us-east-2, sa-east-1, etc.)
  region = var.region
}

# Alguns serviços de borda (ACM para CloudFront e WAFv2 + CloudFront) exigem us-east-1
provider "aws" {
  alias  = "use1"
  region = "us-east-1"
}

############################################
# EFS (compartilhado entre instâncias do ASG)
############################################

resource "aws_security_group" "efs" {
  name        = "nc-efs-sg"
  description = "Allow NFS (2049) from app SG or VPC CIDR"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name   = "nc-efs-sg"
    Backup = "true"
  })
}

# Egress liberado total (ajuste se quiser sair mais restrito)
resource "aws_vpc_security_group_egress_rule" "efs_all_out" {
  security_group_id = aws_security_group.efs.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# Ingress NFS 2049 a partir do SG do app (se informado)
resource "aws_vpc_security_group_ingress_rule" "efs_nfs_from_app_sg" {
  count = var.app_sg_id != "" ? 1 : 0

  security_group_id              = aws_security_group.efs.id
  referenced_security_group_id   = var.app_sg_id
  from_port                      = 2049
  to_port                        = 2049
  ip_protocol                    = "tcp"
  description                    = "NFS from App SG"
}

# Ingress NFS 2049 a partir do CIDR da VPC (fallback quando não há app SG)
resource "aws_vpc_security_group_ingress_rule" "efs_nfs_from_vpc" {
  count = var.app_sg_id == "" ? 1 : 0

  security_group_id = aws_security_group.efs.id
  cidr_ipv4         = var.vpc_cidr
  from_port         = 2049
  to_port           = 2049
  ip_protocol       = "tcp"
  description       = "NFS from VPC CIDR (fallback)"
}

resource "aws_efs_file_system" "this" {
  encrypted = true

  tags = merge(var.tags, {
    Name   = "nc-efs"
    Backup = "true"
  })
}

resource "aws_efs_mount_target" "mt" {
  for_each        = toset(var.private_subnet_ids)
  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs.id]
}

############################################
# RDS PostgreSQL (Multi-AZ)
############################################

resource "aws_db_subnet_group" "this" {
  name       = "nc-db-subnets"
  subnet_ids = var.private_subnet_ids

  tags = var.tags
}

resource "aws_security_group" "rds" {
  name        = "nc-rds-sg"
  description = "Allow Postgres 5432 from app SG or VPC CIDR"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name   = "nc-rds-sg"
    Backup = "true"
  })
}

resource "aws_vpc_security_group_egress_rule" "rds_all_out" {
  security_group_id = aws_security_group.rds.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# Ingress 5432 a partir do SG do app (se informado)
resource "aws_vpc_security_group_ingress_rule" "rds_from_app_sg" {
  count = var.app_sg_id != "" ? 1 : 0

  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = var.app_sg_id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  description                  = "Postgres from App SG"
}

# Ingress 5432 a partir do CIDR da VPC (fallback)
resource "aws_vpc_security_group_ingress_rule" "rds_from_vpc" {
  count = var.app_sg_id == "" ? 1 : 0

  security_group_id = aws_security_group.rds.id
  cidr_ipv4         = var.vpc_cidr
  from_port         = 5432
  to_port           = 5432
  ip_protocol       = "tcp"
  description       = "Postgres from VPC CIDR (fallback)"
}

resource "aws_db_instance" "this" {
  identifier                 = "nc-postgres"
  engine                     = "postgres"
  engine_version             = var.db_engine_version         # ex.: "15.7"
  instance_class             = var.db_instance_class         # ex.: "db.t4g.medium"
  db_name                    = var.db_name
  username                   = var.db_username
  password                   = var.db_password
  multi_az                   = true

  allocated_storage          = 50
  max_allocated_storage      = 200
  storage_encrypted          = true
  publicly_accessible        = false

  backup_retention_period    = 7
  backup_window              = "07:00-09:00"
  maintenance_window         = "Sun:03:00-Sun:04:00"

  deletion_protection        = true
  skip_final_snapshot        = false

  db_subnet_group_name       = aws_db_subnet_group.this.name
  vpc_security_group_ids     = [aws_security_group.rds.id]

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

############################################
# ACM (us-east-1) com validação DNS em Route53
############################################
resource "aws_acm_certificate" "cf" {
  provider          = aws.use1
  domain_name       = var.domain_name
  validation_method = "DNS"
  tags              = var.tags
}

# Cria 1 registro DNS por dvo (cobre raiz + SANs se houver)
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
# WAFv2 (global/us-east-1) para CloudFront
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

############################################
# AWS Backup – captura por tag Backup = true (EFS/RDS)
############################################
resource "aws_backup_vault" "this" {
  name = "nc-backup-vault"
  tags = var.tags
}

resource "aws_backup_plan" "this" {
  name = "nc-backup-plan"

  rule {
    rule_name         = "daily-7d"
    target_vault_name = aws_backup_vault.this.name

    # Diário às 03:00 UTC (formato correto de cron do EventBridge)
    schedule = "cron(0 3 * * ? *)"

    lifecycle {
      delete_after = 7
      # move_to_cold_storage_after = 0 # opcional
    }
  }
}

# Papel padrão do AWS Backup (use data se já existir; senão crie um resource — ver abaixo)
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

# (Opcional) Caso o data acima falhe porque o role não existe, crie:
# resource "aws_iam_role" "backup" {
#   name = "AWSBackupDefaultServiceRole"
#   assume_role_policy = data.aws_iam_policy_document.backup_trust.json
# }
# resource "aws_iam_role_policy_attachment" "backup_attach_backup" {
#   role       = aws_iam_role.backup.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
# }
# resource "aws_iam_role_policy_attachment" "backup_attach_restore" {
#   role       = aws_iam_role.backup.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
# }
# data "aws_iam_policy_document" "backup_trust" {
#   statement {
#     effect  = "Allow"
#     actions = ["sts:AssumeRole"]
#     principals {
#       type        = "Service"
#       identifiers = ["backup.amazonaws.com"]
#     }
#   }
# }
