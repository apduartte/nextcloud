############################################
# Outputs principais do ambiente Nextcloud
############################################

output "alb_dns_name" {
  description = "DNS público do Application Load Balancer (endpoint de acesso web ao Nextcloud)"
  value       = aws_lb.this.dns_name
}

output "db_endpoint" {
  description = "Endpoint do banco de dados PostgreSQL (RDS) usado pelo Nextcloud"
  value       = aws_db_instance.this.address
  sensitive   = true
}

output "efs_id" {
  description = "ID do sistema de arquivos EFS compartilhado entre as instâncias do ASG"
  value       = aws_efs_file_system.this.id
}
