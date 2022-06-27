# Partial configuration. The other settings (e.g., bucket, region) will be
# passed in from a file via -backend-config arguments to 'terraform init'
# terraform init -backend-config=backend.hcl
terraform {
  backend "s3" {
    key            = "workspaces-example/terraform.tfstate"
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "example" {
  ami           = "ami-08d4ac5b634553e16"
  instance_type = "t2.micro"
  # instance_type = terraform.workspace == "default" ? "t2.medium" : "t2.micro"
}