data "aws_caller_identity" "current" {}

data "aws_route53_zone" "root" {
  name = "${var.hosted_zone}."
}

resource "aws_route53_record" "vault" {
  zone_id = data.aws_route53_zone.public.zone_id
  name    = "vault.${var.hosted_zone}"
  type    = "CNAME"
  ttl     = "300"
  records = [data.kubernetes_service.vault-ui.status.0.load_balancer.0.ingress.0.hostname]

  depends_on = [
    kubernetes_job.vault-initialization,
    helm_release.vault,
    data.kubernetes_service.vault-ui
  ]
}
