resource "aws_db_instance" "example" {
  identifier_prefix   = "${var.cluster_name}"
  engine              = "mysql"
  allocated_storage   = var.db_allocated_storage
  instance_class      = var.db_instance_type
  skip_final_snapshot = true
  db_name             = var.db_name

  # How should we set the username and password?
  # Gotten from the variables.tf file.
  # Picks value from environment variable if set.
  # var.db_username = TF_VAR_db_username
  # var.db_password = TF_VAR_db_password
  username = var.db_username
  password = var.db_password
}
