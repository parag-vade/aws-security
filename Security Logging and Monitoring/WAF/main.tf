terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC
resource "aws_vpc" "waf_lab" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "waf-lab-vpc"
  }
}

# Public subnets
resource "aws_subnet" "public" {
  count = 2  
  vpc_id            = aws_vpc.waf_lab.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "waf-lab-public-${count.index + 1}"
  } 
}


# Internet Gateway
resource "aws_internet_gateway" "waf_lab" {
  vpc_id = aws_vpc.waf_lab.id
  tags = {
    Name = "waf-lab-igw"
  }
}

# Route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.waf_lab.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.waf_lab.id
  }
  tags = {
    Name = "waf-lab-public-rt"
  }
}

# Route table association
resource "aws_route_table_association" "public" {
  count = 2  # ← Back to 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}


# Security Groups
resource "aws_security_group" "alb" {
  vpc_id = aws_vpc.waf_lab.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "waf-lab-alb-sg"
  }
}

resource "aws_security_group" "web" {
  vpc_id = aws_vpc.waf_lab.id
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "waf-lab-web-sg"
  }
}

resource "aws_instance" "web" {
  count                       = 1  # ← Changed from 2 to 1
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public[0].id  # ← Use [0]
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = true
  user_data                   = base64encode(templatefile("${path.module}/userdata.sh", {
    instance_index = 1  # ← Fixed to 1
  }))
  tags = {
    Name = "waf-lab-web-1"
  }
}


# ALB
resource "aws_lb" "web" {
  name               = "waf-lab-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id 
  tags = {
    Name = "waf-lab-alb"
  }
}


resource "aws_lb_target_group" "web" {
  name     = "waf-lab-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.waf_lab.id
  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }
}


resource "aws_lb_target_group_attachment" "web" {
  count            = 1  
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.web[0].id 
  port             = 80
}


resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# WAFv2 Web ACL
resource "aws_wafv2_web_acl" "waf_lab" {
  name        = "waf-lab-webacl"
  description = "Lab Web ACL with DDoS rate limit and UK geo block"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "wafLabWebACL"
    sampled_requests_enabled   = true
  }

  # Rule 1: Block UK (SIMPLE - works)
  rule {
    name     = "BlockUK"
    priority = 1

    action {
      block {}
    }

    statement {
      geo_match_statement {
        country_codes = ["GB"]
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "BlockUK"
      sampled_requests_enabled   = true
    }
  }

# Rule 2: Rate limit (CORRECTED)
rule {
  name     = "RateLimitDDoS"
  priority = 2

  action {
    block {}
  }

  statement {
    rate_based_statement {
      limit                 = var.waf_rate_limit
      aggregate_key_type    = "IP"
      evaluation_window_sec = 300
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "RateLimitDDoS"
    sampled_requests_enabled   = true
  }
}

  tags = {
    Name = "waf-lab-webacl"
  }
}




# Associate WAF with ALB
resource "aws_wafv2_web_acl_association" "alb" {
  resource_arn = aws_lb.web.arn
  web_acl_arn  = aws_wafv2_web_acl.waf_lab.arn
}
