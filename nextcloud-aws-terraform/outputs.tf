
output "alb_dns" {
  value       = module.alb.lb_dns_name
  description = "DNS público do ALB"
}

output "efs_id" {
  value       = aws_efs_file_system.nextcloud.id
  description = "ID do EFS"
}

output "rds_endpoint" {
  value       = aws_db_instance.this.address
  description = "Endpoint do banco PostgreSQL"
}

output "asg_name" {
  value       = aws_autoscaling_group.nextcloud.name
  description = "Nome do ASG"
}
