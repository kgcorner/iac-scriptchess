module "site" {
  source = "../../modules/site"

  name            = "scriptchess-dev"
  aliases         = ["dev.scriptchess.com"]
  origin_id       = "dev"
  origin_domain   = "dev.scriptchess.com.s3-website.ap-south-1.amazonaws.com"
  certificate_arn = "arn:aws:acm:us-east-1:892573662818:certificate/12116b1c-a6a7-42d8-b4db-14ddd9cebe2e"
  function_file   = "${path.module}/../../functions/viewer-request.js"
  hsts            = true # dev first, so a problem shows up here before prod
}


output "distribution_id" {
  value = module.site.distribution_id
}

module "bucket" {
  source = "../../modules/website-bucket"

  bucket = "dev.scriptchess.com"
}

# The scriptchess.com zone is shared by dev and prod, so it is not managed here. This stack only
# owns its own record in it.
data "aws_route53_zone" "main" {
  name         = "scriptchess.com"
  private_zone = false
}

resource "aws_route53_record" "dev" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "dev.scriptchess.com"
  type    = "A"

  alias {
    name                   = module.site.domain_name
    zone_id                = module.site.hosted_zone_id
    evaluate_target_health = false
  }
}
