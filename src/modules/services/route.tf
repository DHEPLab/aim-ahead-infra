resource "aws_acm_certificate" "certificate" {
  domain_name               = local.domain_name
  subject_alternative_names = ["*.${local.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_route53_zone" "hosted_zone" {
  name = local.domain_name
}


resource "aws_route53_record" "sub_app_record" {
  zone_id = aws_route53_zone.hosted_zone.zone_id
  name    = var.env == "prod" ? "${local.subdomain}.${local.domain_name}" : "${local.subdomain}-${var.env}.${local.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.application_load_balancer.dns_name
    zone_id                = aws_lb.application_load_balancer.zone_id
    evaluate_target_health = true
  }
}