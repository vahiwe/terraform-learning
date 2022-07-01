# Partial configuration. The other settings (e.g., bucket, region) will be
# passed in from a file via -backend-config arguments to 'terraform init'
# terraform init -backend-config=backend.hcl
terraform {
  backend "s3" {
    key            = "stage/data-stores/mysql/terraform.tfstate"
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_db_instance" "example" {
  identifier_prefix   = "terraform-up-and-running"
  engine              = "mysql"
  allocated_storage   = 10
  instance_class      = "db.t2.micro"
  skip_final_snapshot = true
  db_name             = "example_database"

  # How should we set the username and password?
  # Gotten from the variables.tf file.
  # Picks value from environment variable if set.
  # var.db_username = TF_VAR_db_username
  # var.db_password = TF_VAR_db_password
  username = var.db_username
  password = var.db_password
}
