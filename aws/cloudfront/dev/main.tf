module "site" {
  source = "../modules/site"

  name            = "scriptchess-dev"
  aliases         = ["dev.scriptchess.com"]
  origin_id       = "dev"
  origin_domain   = "dev.scriptchess.com.s3-website.ap-south-1.amazonaws.com"
  certificate_arn = "arn:aws:acm:us-east-1:892573662818:certificate/12116b1c-a6a7-42d8-b4db-14ddd9cebe2e"
  function_file   = "${path.module}/../functions/viewer-request.js"
  hsts            = true # dev first, so a problem shows up here before prod
}

# Adopt the existing distribution instead of creating a new one. Remove this block once it is applied.
import {
  to = module.site.aws_cloudfront_distribution.this
  id = var.distribution_id
}

output "distribution_id" {
  value = module.site.distribution_id
}
