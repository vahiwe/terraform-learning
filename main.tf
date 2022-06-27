provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "web" {
  instance_type = "t2.micro"
  ami = "ami-08d4ac5b634553e16"
  user_data_replace_on_change = true
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF

  tags = {
    Name = "terraform-example"
  }
}

resource "aws_security_group" "web_sg" {
    name = "terraform-example-web-sg"

    ingress {
      cidr_blocks = [ "0.0.0.0/0" ]
      description = "Allow all from anywhere to port 8080"
      from_port = 8080
      protocol = "tcp"
      to_port = 8080
    } 
}