variable "project_name" {
  type    = string
  default = "nextcloud-efs"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "public_cidrs" {
  type    = list(string)
  default = ["10.10.0.0/24", "10.10.1.0/24"]
}

variable "private_cidrs" {
  type    = list(string)
  default = ["10.10.10.0/24", "10.10.11.0/24"]
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "key_name" {
  type        = string
  default     = null
  description = "Nome opcional da chave SSH para acesso EC2."
}

variable "db_username" {
  type    = string
  default = "nextcloud"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_name" {
  type    = string
  default = "nextcloud"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

variable "trusted_domains" {
  type        = string
  default     = "nextcloud.example.com"
  description = "Domínio confiável para acesso ao Nextcloud."
}

variable "enable_https" {
  type        = bool
  default     = false
  description = "Se verdadeiro, configura HTTPS no ALB com ACM."
}

variable "acm_certificate_arn" {
  type        = string
  default     = null
  description = "ARN do certificado ACM para HTTPS."
}
