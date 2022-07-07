# Partial configuration. The other settings (e.g., bucket, region) will be
# passed in from a file via -backend-config arguments to 'terraform init'
# terraform init -backend-config=backend.hcl
terraform {
  backend "s3" {
    key  = "stage/data-stores/mysql/terraform.tfstate"
  }
}

provider "aws" {
  region = "us-east-1"
}

module "mysql" {
  source = "../../../modules/data-stores/mysql"

  cluster_name     = "mysql-stage"
  db_instance_type = "db.t2.micro"
  db_name          = "stage-mysql"
  db_allocated_storage = 10
  
  db_username      = var.db_username
  db_password      = var.db_password
}