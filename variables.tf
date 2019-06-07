# variables injected from `terraform.tfvars`
variable "region" {}
variable "shared_credentials_file" {}
variable "profile" {}

variable "s3_config_bucket" {
  description = "S3 bucket name used for terraform remote configuration"
}


#
# terraform plan -var "name=example"
#
variable "name" {
  type    = "string"
  default = "example"
}
