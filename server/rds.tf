resource "random_password" "main_db_password" {
  length           = 40
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}


resource "aws_kms_key" "main_db_kms_key" {
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  key_usage                = "ENCRYPT_DECRYPT"

  tags = {
    "environment" = var.environment
    "product"     = var.product_name
  }
}

resource "aws_kms_alias" "main_db_kms_key_alias" {
  name          = "alias/${var.product_name}-main-db-kms-key"
  target_key_id = aws_kms_key.main_db_kms_key.key_id
}

resource "aws_ssm_parameter" "main_db_parameter" {
  name   = "${var.product_name}/api/main_db_password"
  type   = "SecureString"
  value  = aws_rds_cluster.main_db_cluster.master_password
  key_id = aws_kms_key.main_db_kms_key.id

  tags = {
    "environment" = var.environment
    "product"     = var.product_name
  }
}


resource "aws_security_group" "db_security_group" {
  name   = "${var.product_name}_db_security_group"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.api_security_group.id]
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

resource "aws_db_subnet_group" "main_db_subnet_group" {
  name       = "${var.product_name}-main-db-subnet-group"
  subnet_ids = module.vpc.private_subnets

  tags = {
    "environment" = var.environment
    "product"     = var.product_name
  }
}

resource "aws_rds_cluster" "main_db_cluster" {
  engine      = "aurora-mysql"
  engine_mode = "serverless"

  database_name   = "rails_tutorial"
  master_username = "rails"
  master_password = random_password.main_db_password.result

  apply_immediately = true
  storage_encrypted = true
  port              = 3306

  vpc_security_group_ids = [aws_security_group.db_security_group.id]
  db_subnet_group_name   = aws_db_subnet_group.main_db_subnet_group.name
  kms_key_id             = aws_kms_key.main_db_kms_key.arn

  lifecycle {
    ignore_changes = [
      master_password,
    ]
  }

  serverlessv2_scaling_configuration {
    max_capacity = 1.0
    min_capacity = 0.5
  }

  tags = {
    "environment" = var.environment
    "product"     = var.product_name
  }
}


resource "aws_rds_cluster_instance" "main_db_instance" {
  count                = 1
  engine               = aws_rds_cluster.main_db_cluster.engine
  engine_version       = aws_rds_cluster.main_db_cluster.engine_version
  cluster_identifier   = aws_rds_cluster.main_db_cluster.id
  instance_class       = "db.t4g.micro"
  db_subnet_group_name = aws_db_subnet_group.main_db_subnet_group.name
  publicly_accessible  = false
}
