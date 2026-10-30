module "site" {
  source = "../modules/site"

  name      = "scriptchess-prod"
  aliases   = ["scriptchess.com", "www.scriptchess.com"]
  origin_id = "scriptchess.com-origin"
  # OPEN QUESTION: this is the bucket prod serves today, but the deploy workflow writes to the
  # "scriptchess.com" bucket. Confirm which one is right before applying prod.
  origin_domain   = "www.scriptchess.com.s3-website.ap-south-1.amazonaws.com"
  certificate_arn = "arn:aws:acm:us-east-1:892573662818:certificate/e1536fa7-9dad-4ea7-90b7-075fc03c4a35"
  function_file   = "${path.module}/../functions/viewer-request.js"
  hsts            = false # switch to true after prod has run on HTTPS only for a while
  logging_bucket  = "scriptchess-logs.s3.amazonaws.com"
}

# Adopt the existing distribution instead of creating a new one. Remove this block once it is applied.
import {
  to = module.site.aws_cloudfront_distribution.this
  id = var.distribution_id
}

output "distribution_id" {
  value = module.site.distribution_id
}
