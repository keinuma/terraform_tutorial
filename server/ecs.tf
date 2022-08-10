resource "aws_ecs_cluster" "api_cluster" {
  name = "${var.product_name}-api"

  tags = {
    "environment" = var.environment
    "product"     = var.product_name
  }
}
