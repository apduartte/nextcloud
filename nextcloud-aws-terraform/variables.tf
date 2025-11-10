
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "desired_capacity" {
  type    = number
  default = 1
}

variable "min_size" {
  type    = number
  default = 1
}

variable "max_size" {
  type    = number
  default = 2
}

variable "db_name" {
  type    = string
  default = "nextcloud"
}

variable "db_username" {
  type    = string
  default = "nextcloud"
}

variable "db_password" {
  type      = string
  sensitive = true
  default   = "NextcloudDB2024!Secure"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_allocated_gb" {
  type    = number
  default = 20
}

variable "db_engine_version" {
  type    = string
  default = "15.5"
}

variable "app_fqdn" {
  description = "FQDN do Nextcloud"
  type        = string
  default     = "nextcloud.apduartte.com.br"
}

variable "tags" {
  type = map(string)
  default = {
    Project = "Nextcloud-IaC"
    Owner   = "AnaPaulaDuarte"
  }
}
variable "enable_destroy" {
  type        = bool
  default     = false
  description = "Protege contra destruição acidental"
}

variable "nextcloud" {
  type        = string
  description = "apduartte/nextcloud"
}

variable "project_repo" {
  type        = string
  default     = "nextcloud" 
  description = "apduartte/nextcloud"
}
