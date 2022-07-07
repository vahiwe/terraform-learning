# Partial configuration. The other settings (e.g., bucket, region) will be
# passed in from a file via -backend-config arguments to 'terraform init'
# terraform init -backend-config=backend.hcl
terraform {
  backend "s3" {
    key  = "prod/data-stores/mysql/terraform.tfstate"
  }
}

provider "aws" {
  region = "us-east-1"
}

module "mysql" {
  source = "../../../modules/data-stores/mysql"

  cluster_name     = "mysql-prod"
  db_instance_type = "db.t2.micro"
  db_name          = "prodmysql"
  db_allocated_storage = 10
  
  # How should we set the username and password?
  # Gotten from the variables.tf file.
  # Picks value from environment variable if set.
  # var.db_username = TF_VAR_db_username
  # var.db_password = TF_VAR_db_password
  db_username      = var.db_username
  db_password      = var.db_password

}