data "aws_availability_zones" "available" {
  state = "available"
}

######################
# VPC
######################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.2"

  name = "main_vpc"
  cidr = "10.0.0.0/16"

  azs             = data.aws_availability_zones.available.names
  private_subnets = slice(var.private_subnet_cidr_blocks, 0, 2)
  public_subnets  = slice(var.public_subnet_cidr_blocks, 0, 2)

  enable_nat_gateway = false
  enable_vpn_gateway = false


  tags = {
    "environment" = var.environment
    "product"     = var.product_name
  }
}


######################
# Secutiry Group
######################
resource "aws_security_group" "alb_security_group" {
  name   = "${var.product_name}_alb_security_group"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
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
    "environment" = var.environment
    "product"     = var.product_name
  }
}

resource "aws_security_group" "api_security_group" {
  name   = "${var.product_name}_api_security_group"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port       = "3000"
    to_port         = "3000"
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_security_group.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "environment" = var.environment
    "product"     = var.product_name
  }
}


######################
# ALB
######################
resource "aws_alb" "main_alb" {
  security_groups    = [aws_security_group.alb_security_group.id]
  load_balancer_type = "application"
  subnets            = module.vpc.public_subnets

  tags = {
    "environment" = var.environment
    "product"     = var.product_name
  }
}


resource "aws_alb_listener" "main_alb_listner" {
  load_balancer_arn = aws_alb.main_alb.arn
  port              = "443"
  protocol          = "HTTPS"

  certificate_arn = aws_acm_certificate.api_acm_certifacate.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.main_alb_target_group.arn
  }

  tags = {
    "environment" = var.environment
    "product"     = var.product_name
  }
}

resource "aws_alb_target_group" "main_alb_target_group" {
  port     = 3000
  protocol = "HTTP"

  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    path = "/"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    "environment" = var.environment
    "product"     = var.product_name
  }
}
