# Providers
provider "aws" {
  region = "us-east-1"
}

# Alguns serviços de borda (ACM para CloudFront e WAFv2 + CloudFront) exigem us-east-1
provider "aws" {
  alias  = "use1"
  region = "us-east-1"
}
