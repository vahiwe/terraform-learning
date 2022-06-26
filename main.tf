provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "web" {
  instance_type = "t2.micro"
  ami = "ami-08d4ac5b634553e16"
  tags = {
    Name = "terraform-example"
  }
}