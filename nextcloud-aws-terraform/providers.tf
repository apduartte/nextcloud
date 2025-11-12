terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # ou fixe exatamente "5.100.0" se quiser builds 100% reproduzíveis
    }
  }
}

provider "aws" {
  region = var.region
}
