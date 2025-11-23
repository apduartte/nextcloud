## backend.tf
terraform {
  required_version = ">= 1.6"
  backend "s3" {
    bucket         = "apduartte-nextcloud-terraform-state"
    key            = "nextcloud/terraform.tfstate"
    region         = "us-east-1"
   #dynamodb_table = "# TODO: terraform-locks"
    encrypt        = true
  }
}
