resource "aws_route53_zone" "root" {
  name = var.root_domain_name
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    "environment" = var.environment
    "product"     = var.product_name
  }
}

resource "aws_route53_record" "api" {
  zone_id = aws_route53_zone.root.zone_id
  name    = "rails.${var.root_domain_name}"
  type    = "A"

  alias {
    name                   = aws_alb.main_alb.dns_name
    zone_id                = aws_alb.main_alb.zone_id
    evaluate_target_health = true
  }
}
