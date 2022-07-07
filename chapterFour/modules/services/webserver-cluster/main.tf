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

data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = var.db_remote_state_bucket
    key    = var.db_remote_state_key
    region = "us-east-1"
  }
}

resource "aws_launch_configuration" "web_launch_configuration" {
  instance_type = var.instance_type
  image_id = "ami-08d4ac5b634553e16"
  security_groups = [aws_security_group.web_sg.id]

  # Render the User Data script as a template
  user_data = templatefile("user-data.sh", {
    server_port = var.server_port
    db_address  = data.terraform_remote_state.db.outputs.address
    db_port     = data.terraform_remote_state.db.outputs.port
  })

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

    min_size = var.min_size
    max_size = var.max_size
    
    tag {
        key = "Name"
        value = "${var.cluster_name}-asg"
        propagate_at_launch = true
        }
}

resource "aws_security_group" "web_sg" {
    name = "${var.cluster_name}-web-sg"

    ingress {
      cidr_blocks = [ "0.0.0.0/0" ]
      description = "Allow all from anywhere to port 8080"
      from_port = var.server_port
      protocol = "tcp"
      to_port = var.server_port
    } 
}

resource "aws_lb" "web_alb" {
    name = "${var.cluster_name}-alb"
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
  name = "${var.cluster_name}-alb-sg"

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
  name     = "${var.cluster_name}-asg-tg"
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