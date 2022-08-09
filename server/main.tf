resource "aws_ecr_repository" "api" {
  name                 = "${var.product_name}_sample"
  image_tag_mutability = "IMMUTABLE"

  encryption_configuration {
    encryption_type = "AES256"
  }

  image_scanning_configuration {
    scan_on_push = "true"
  }
}
