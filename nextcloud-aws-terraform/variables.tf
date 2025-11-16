variable "enable_cloudfront" {
  type = bool
  default = true
}

# Se no futuro quiser usar domínio próprio, pode usar isso:
variable "cloudfront_aliases" {
  type = list(string)
  default = []
  description = "CNAMEs/aliases para a distribuição (ex.: cdn.apduartte.com.br)"
}