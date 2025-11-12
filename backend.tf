## backend.tf
```hcl
terraform {
required_version = ">= 1.6"
backend "s3" {
bucket = "# TODO: seu-estado-terraform"
key = "nextcloud/terraform.tfstate"
region = "# TODO: us-east-1"
dynamodb_table = "# TODO: terraform-locks"
encrypt = true
}
}
