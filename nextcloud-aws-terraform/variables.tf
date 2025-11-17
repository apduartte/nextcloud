############################################
# Variáveis principais do projeto
############################################

variable "project_name" {
  type        = string
  description = "Nome base do projeto (prefixo dos recursos AWS)"
  default     = "nextcloud-efs"
}

variable "region" {
  type        = string
  description = "Região AWS onde os recursos serão criados"
  default     = "us-east-1"
}

############################################
# VPC e Subnets
############################################

variable "vpc_cidr" {
  type        = string
  description = "CIDR principal da VPC do projeto"
  default     = "10.10.0.0/16"
}

variable "azs" {
  type        = list(string)
  description = "Zonas de disponibilidade utilizadas pela VPC"
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_cidrs" {
  type        = list(string)
  description = "CIDRs das subnets públicas da VPC"
  default     = ["10.10.0.0/24", "10.10.1.0/24"]
}

variable "private_cidrs" {
  type        = list(string)
  description = "CIDRs das subnets privadas da VPC"
  default     = ["10.10.10.0/24", "10.10.11.0/24"]
}

############################################
# Tags padronizadas
############################################

variable "tags" {
  type        = map(string)
  description = "Tags aplicadas a todos os recursos"
  default = {
    Project   = "nextcloud-efs"
    Owner     = "Ana"
    ManagedBy = "terraform"
  }
}

############################################
# Proteção contra destruição acidental
# false (padrão) -> proteção LIGADA
# true           -> proteção DESLIGADA
############################################

variable "enable_destroy" {
  type        = bool
  description = "Define se a proteção contra destruição está desligada (true) ou ligada (false - padrão)."
  default     = false
}

############################################
# Domínios e DNS
############################################

variable "domain_name" {
  type        = string
  description = "Nome de domínio público usado para ALB/CloudFront (ex.: nextcloud.seu-dominio.com.br). Opcional."
  default     = ""
}

variable "hosted_zone_id" {
  type        = string
  description = "ID da Hosted Zone do Route 53 usada para criar/validar registros DNS e certificados ACM."
  default     = ""
}

############################################
# HTTPS no ALB
############################################

variable "enable_https" {
  type        = bool
  description = "Ativa listener HTTPS no ALB e redirecionamento HTTP → HTTPS quando true."
  default     = false
}

variable "acm_certificate_arn" {
  type        = string
  description = "ARN do certificado ACM usado no ALB quando HTTPS está habilitado. Deixe vazio para usar apenas HTTP."
  default     = ""
}

############################################
# CDN / CloudFront
############################################

variable "enable_cloudfront" {
  type        = bool
  description = "Define se a distribuição CloudFront para o Nextcloud será criada."
  default     = false
}

############################################
# EC2 / Auto Scaling (Nextcloud)
############################################

variable "instance_type" {
  type        = string
  description = "Tipo da instância EC2 usada no Auto Scaling Group para o Nextcloud"
  default     = "t3.small"
}

variable "key_name" {
  type        = string
  description = "Nome da Key Pair usada para acesso SSH às instâncias EC2 (deixe vazio se não for usar SSH)"
  default     = ""
}

############################################
# Banco de Dados RDS PostgreSQL
############################################

variable "db_instance_class" {
  type        = string
  description = "Classe da instância RDS PostgreSQL (ex.: db.t3.micro)"
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  type        = number
  description = "Tamanho do armazenamento alocado para o RDS (em GB)"
  default     = 20
}

variable "db_name" {
  type        = string
  description = "Nome do banco de dados PostgreSQL usado pelo Nextcloud"
  default     = "nextcloud"
}

variable "db_username" {
  type        = string
  description = "Usuário do banco de dados PostgreSQL"
  default     = "nextcloud"
}

variable "db_password" {
  type        = string
  description = "Senha do banco de dados PostgreSQL (recomenda-se definir via TF_VAR_db_password)"
  sensitive   = true
  default     = ""
}

############################################
# Aplicação Nextcloud
############################################

variable "trusted_domains" {
  type        = string
  description = "Domínios confiáveis configurados no Nextcloud (ex.: nextcloud.seu-dominio.com.br ou DNS do ALB)"
  default     = "nextcloud.seu-dominio.com.br"
}
