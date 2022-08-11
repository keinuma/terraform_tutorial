resource "aws_acm_certificate" "api_acm_certifacate" {
  domain_name       = "rails.${var.root_domain_name}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    "environment" = var.environment
    "product"     = var.product_name
  }
}

resource "aws_acm_certificate_validation" "api_acm_certificate_validation" {
  certificate_arn         = aws_acm_certificate.api_acm_certifacate.arn
  validation_record_fqdns = [aws_route53_record.api.fqdn]
}

resource "aws_route53_record" "api_cert_verification_r53_record" {
  allow_overwrite = true
  name            = aws_acm_certificate.api_acm_certifacate.domain_validation_options.value.name
  records         = [aws_acm_certificate.api_acm_certifacate.domain_validation_options.value.record]
  ttl             = 60
  type            = aws_acm_certificate.api_acm_certifacate.domain_validation_options.value.type
  zone_id         = aws_route53_record.api.zone_id
}
