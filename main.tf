provider "aws" {
  region = "us-east-1"
}

variable "server_port" {
    default = 8080
    type = number
    description = "The port the server will use for HTTP requests"
}

# Get default VPC and subnet IDs
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_launch_configuration" "web_launch_configuration" {
  instance_type = "t2.micro"
  image_id = "ami-08d4ac5b634553e16"
  security_groups = [aws_security_group.web_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF

  # Required when using a launch configuration with an auto scaling group.
  lifecycle {
    create_before_destroy = true
  }   
}

resource "aws_autoscaling_group" "web_asg" {
    launch_configuration = aws_launch_configuration.web_launch_configuration.name
    vpc_zone_identifier = data.aws_subnets.default.ids

    min_size = 2
    max_size = 10
    
    tag {
        key = "Name"
        value = "web-asg"
        propagate_at_launch = true
        }
}



resource "aws_security_group" "web_sg" {
    name = "terraform-example-web-sg"

    ingress {
      cidr_blocks = [ "0.0.0.0/0" ]
      description = "Allow all from anywhere to port 8080"
      from_port = var.server_port
      protocol = "tcp"
      to_port = var.server_port
    } 
}