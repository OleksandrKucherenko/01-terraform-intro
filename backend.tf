# Remote configuration, no variables allowed
# https://www.terraform.io/docs/backends/types/s3.html
terraform {
  backend "s3" {
    bucket  = "01-example-terraform-remote-state"  # <- should match `terraform.tfvars/s3_config_bucket`
    key     = "terraform.tfstate"
    encrypt = true
    region  = "eu-north-1"
  }
}
