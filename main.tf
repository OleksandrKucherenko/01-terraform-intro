# References:
#   https://jaxenter.com/tutorial-aws-terraform-147881.html
#   https://hackernoon.com/introduction-to-aws-with-terraform-7a8daf261dc0
#   https://learn.hashicorp.com/terraform/getting-started/build
#   https://blog.gruntwork.io/an-introduction-to-terraform-f17df9c6d180
#   https://rangle.io/blog/frontend-app-in-aws-with-terraform/
#   https://www.terraform-best-practices.com/code-structure
#   https://cloudcraft.co/
#
# Registry:
#   https://registry.terraform.io/

provider "aws" {
  shared_credentials_file = "${var.shared_credentials_file}"
  profile                 = "${var.profile}"
  region                  = "${var.region}"
}

# https://github.com/rangle/tutorial-frontend-site-terraform/blob/master/s3bucket.tf
resource "aws_s3_bucket" "s3_www" {
  # unique name across _all_ aws accounts
  bucket        = "${terraform.workspace}-${var.name}-www-storage"
  acl           = "private"
  force_destroy = true

  website {
    index_document = "index.html"
    error_document = "404.html"
  }

  # tags {
  #   Environement = "${terraform.workspace}"
  # }
}

resource "aws_instance" "example" {
  # find AMIs: `aws ec2 describe-images --owners self amazon`
  # https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/finding-an-ami.html
  ami           = "ami-"
  instance_type = "t2.micro"

  # tags {
  #   Name = "example"
  # }
}

