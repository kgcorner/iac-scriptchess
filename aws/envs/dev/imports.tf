# Adopt the existing dev bucket and DNS record. Delete this file after the first successful apply.

import {
  to = module.bucket.aws_s3_bucket.this
  id = local.domain
}

import {
  to = module.bucket.aws_s3_bucket_website_configuration.this
  id = local.domain
}

import {
  to = module.bucket.aws_s3_bucket_public_access_block.this
  id = local.domain
}

import {
  to = module.bucket.aws_s3_bucket_policy.public_read
  id = local.domain
}

import {
  to = module.bucket.aws_s3_bucket_server_side_encryption_configuration.this
  id = local.domain
}

# <zone id>_<record name>_<type>; zone Z0794218UM60ESHGZL1C is scriptchess.com
import {
  to = aws_route53_record.dev
  id = "Z0794218UM60ESHGZL1C_${local.domain}_A"
}
