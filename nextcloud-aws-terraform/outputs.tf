## outputs.tf
```hcl
output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "db_endpoint" {
  value = aws_db_instance.this.address
}

output "efs_id" {
  value = aws_efs_file_system.this.id
}
```
