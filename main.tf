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

    target_group_arns = [aws_lb_target_group.asg.arn]
    health_check_type = "ELB"

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

resource "aws_lb" "web_alb" {
    name = "terraform-example-web-alb"
    subnets = data.aws_subnets.default.ids
    load_balancer_type = "application"
    security_groups = [ aws_security_group.web_alb.id ]
}

resource "aws_lb_listener" "web_alb_listener" {
    load_balancer_arn = aws_lb.web_alb.arn
    protocol = "HTTP"
    port = "80"

    # By default, return a simple 404 page
    default_action {
      type = "fixed-response"

      fixed_response {
        content_type = "text/plain"
        message_body = "404: page not found"
        status_code  = 404
      }
    }
}

resource "aws_security_group" "web_alb" {
  name = "terraform-example-alb"

  # Allow inbound HTTP requests
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound requests
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_target_group" "asg" {
  name     = "terraform-asg-example"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.web_alb_listener.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}

output "alb_dns_name" {
  value       = aws_lb.web_alb.dns_name
  description = "The domain name of the load balancer"
}