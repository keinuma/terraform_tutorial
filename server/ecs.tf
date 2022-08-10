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
  tags = {
    "environment" = var.environment
    "product"     = var.product_name
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.api_ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "api_ecs_task_role" {
  name               = "${var.product_name}-ApiTaskRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_role_assume_policy.json
  tags = {
    "environment" = var.environment
    "product"     = var.product_name
  }
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
          "awslogs-group" : "/ecs/app",
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
