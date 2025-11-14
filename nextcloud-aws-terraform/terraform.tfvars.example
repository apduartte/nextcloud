# terraform.tfvars

# Identificação do projeto
project_name = "nextcloud-lab-ana"

# Região da AWS
region = "us-east-1"

# VPC e sub-redes (pode manter se não tiver conflito na sua conta)
vpc_cidr      = "10.10.0.0/16"
azs           = ["us-east-1a", "us-east-1b"]
public_cidrs  = ["10.10.0.0/24", "10.10.1.0/24"]
private_cidrs = ["10.10.10.0/24", "10.10.11.0/24"]

# EC2 do Nextcloud
# t3.small = mais confortável | t3.micro = mais barato
instance_type = "t3.small"

# Chave SSH (se quiser conseguir acessar a EC2)
# Use o nome exato da Key Pair que já existe na região.
key_name = "SUA_KEYPAIR_AQUI" # ou null se não for acessar via SSH

# Banco de Dados RDS PostgreSQL
db_username          = "nextcloud"
db_password          = "SenhaForte123!" # NÃO commitar isso no Git
db_name              = "nextcloud"
db_allocated_storage = 20

# Domínio confiável do Nextcloud
# Para teste, pode ser o próprio DNS do ALB; em produção, o seu domínio.
trusted_domains = "nextcloud.seu-dominio.com.br"

# HTTPS no ALB (integração com ACM)
# Para primeiro teste, pode deixar falso e usar HTTP.
enable_https        = false
acm_certificate_arn = null
