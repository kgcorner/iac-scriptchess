# Adopt the existing image bucket and distribution. Delete this file after the first successful apply.

import {
  to = aws_s3_bucket.media
  id = local.bucket
}

import {
  to = aws_s3_bucket_policy.public_read
  id = local.bucket
}

import {
  to = aws_s3_bucket_cors_configuration.media
  id = local.bucket
}

import {
  to = aws_s3_bucket_server_side_encryption_configuration.media
  id = local.bucket
}

import {
  to = aws_s3_bucket_ownership_controls.media
  id = local.bucket
}

import {
  to = aws_cloudfront_distribution.media
  id = "E3HTG46HEMC69M"
}
