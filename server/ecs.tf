data "aws_caller_identity" "me" {}

######################
# IAM Role
######################
data "aws_iam_policy_document" "ecs_task_role_assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "api_ecs_task_execution_role" {
  name               = "${var.product_name}-ApiTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_role_assume_policy.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    aws_iam_policy.api_parameters_policy.arn
  ]

  tags = {
    "environment" = var.environment
    "product"     = var.product_name
  }
}

resource "aws_iam_policy" "api_parameters_policy" {
  name   = "${var.product_name}-ApiParamsPolicy"
  path   = "/"
  policy = data.aws_iam_policy_document.api_parameters_permissions.json

  tags = {
    "environment" = var.environment
    "product"     = var.product_name
  }
}
data "aws_iam_policy_document" "api_parameters_permissions" {
  statement {
    sid = "SSMSessionManagerPermissions"
    actions = [
      "ssm:GetParameters",
      "secretsmanager:GetSecretValue",
      "kms:Decrypt"
    ]
    effect = "Allow"
    resources = [
      "arn:aws:ssm:ap-northeast-1:${data.aws_caller_identity.me.account_id}:parameter/${var.product_name}/api/*",
      aws_kms_key.main_db_kms_key.arn
    ]
  }
}

resource "aws_iam_policy" "api_ecs_exec_ssm_policy" {
  name   = "${var.product_name}-ApiECSExecSSMPolicy"
  path   = "/"
  policy = data.aws_iam_policy_document.api_ecs_exec_ssm.json

  tags = {
    "environment" = var.environment
    "product"     = var.product_name
  }
}
data "aws_iam_policy_document" "api_ecs_exec_ssm" {
  statement {
    effect = "Allow"
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "api_ecs_task_role" {
  name                = "${var.product_name}-ApiTaskRole"
  assume_role_policy  = data.aws_iam_policy_document.ecs_task_role_assume_policy.json
  managed_policy_arns = [aws_iam_policy.api_ecs_exec_ssm_policy.arn]
  tags = {
    "environment" = var.environment
    "product"     = var.product_name
  }
}

######################
# Cloudwatch
######################
resource "aws_cloudwatch_log_group" "main_log_group" {
  name = "/ecs/app"
}

######################
# ECS
######################
resource "aws_ecs_cluster" "api_cluster" {
  name = "${var.product_name}-api"

  tags = {
    "environment" = var.environment
    "product"     = var.product_name
  }
}

resource "aws_ecs_service" "api_service" {
  name                   = "${var.product_name}-api"
  cluster                = aws_ecs_cluster.api_cluster.id
  launch_type            = "FARGATE"
  enable_execute_command = true
  platform_version       = "1.4.0"
  desired_count          = 1

  task_definition = aws_ecs_task_definition.api_task_definition.arn

  load_balancer {
    container_name   = "app"
    container_port   = "3000"
    target_group_arn = aws_alb_target_group.main_alb_target_group.arn
  }

  network_configuration {
    assign_public_ip = true
    security_groups  = [aws_security_group.api_security_group.id]
    subnets          = module.vpc.public_subnets
  }

  lifecycle {
    ignore_changes = [desired_count, task_definition]
  }

  tags = {
    "environment" = var.environment
    "product"     = var.product_name
  }
}

resource "aws_ecs_task_definition" "api_task_definition" {
  family                   = "${var.product_name}-api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  task_role_arn            = aws_iam_role.api_ecs_task_role.arn
  execution_role_arn       = aws_iam_role.api_ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      "name" : "app",
      "image" : "${aws_ecr_repository.api.repository_url}",
      "essential" : true,
      "portMappings" : [
        {
          "containerPort" : 3000,
          "hostPort" : 3000
        }
      ],
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group" : "${aws_cloudwatch_log_group.main_log_group.name}",
          "awslogs-region" : "ap-northeast-1",
          "awslogs-stream-prefix" : "${var.product_name}-api"
        }
      }
    }
  ])

  tags = {
    "environment" = var.environment
    "product"     = var.product_name
  }
}
