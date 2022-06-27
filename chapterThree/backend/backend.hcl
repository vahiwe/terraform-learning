# backend.hcl
bucket         = "terraform-up-and-running-state-593493008121"
region         = "us-east-1"
dynamodb_table = "terraform-up-and-running-locks"
encrypt        = true