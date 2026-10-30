# Adopt the existing dev bucket and DNS record. Delete this file after the first successful apply.

import {
  to = module.bucket.aws_s3_bucket.this
  id = "dev.scriptchess.com"
}

import {
  to = module.bucket.aws_s3_bucket_website_configuration.this
  id = "dev.scriptchess.com"
}

import {
  to = module.bucket.aws_s3_bucket_public_access_block.this
  id = "dev.scriptchess.com"
}

import {
  to = module.bucket.aws_s3_bucket_policy.public_read
  id = "dev.scriptchess.com"
}

import {
  to = module.bucket.aws_s3_bucket_server_side_encryption_configuration.this
  id = "dev.scriptchess.com"
}

# <zone id>_<record name>_<type>; zone Z0794218UM60ESHGZL1C is scriptchess.com
import {
  to = aws_route53_record.dev
  id = "Z0794218UM60ESHGZL1C_dev.scriptchess.com_A"
}
