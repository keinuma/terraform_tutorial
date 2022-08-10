output "api_ecr_repo_arn" {
  value = aws_ecr_repository.api.arn
}

output "api_ecs_cluster_name" {
  value = aws_ecs_cluster.api_cluster.name
}

output "api_ecs_service_name" {
  value = aws_ecs_service.api_service.name
}

output "api_ecs_service_arn" {
  value = aws_ecs_service.api_service.id
}

output "api_ecs_task_role_arn" {
  value = aws_iam_role.api_ecs_task_role.arn
}

output "api_ecs_task_execution_role_arn" {
  value = aws_iam_role.api_ecs_task_execution_role.arn
}
