############################################
# Provider AWS - Região principal do projeto
############################################

provider "aws" {
  region = var.region

  # OPCIONAL: se quiser aplicar tags padrão em todos os recursos suportados
  # default_tags {
  #   tags = var.tags
  # }
}

############################################
# Provider AWS (alias) - us-east-1 para serviços globais
# Usado por:
# - ACM para CloudFront
# - WAFv2 com scope = CLOUDFRONT
# - Outros serviços que exigem us-east-1
############################################

provider "aws" {
  alias  = "use1"
  region = "us-east-1"

  # default_tags {
  #   tags = var.tags
  # }
}
