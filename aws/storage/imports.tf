# Adopt the existing buckets. Delete this file after the first successful apply.
# Every import id is the bucket name.

import {
  to = aws_s3_bucket.state
  id = "scriptchess-state"
}

import {
  to = aws_s3_bucket_versioning.state
  id = "scriptchess-state"
}

import {
  to = aws_s3_bucket_public_access_block.state
  id = "scriptchess-state"
}

import {
  to = aws_s3_bucket_server_side_encryption_configuration.state
  id = "scriptchess-state"
}

import {
  to = aws_s3_bucket_ownership_controls.state
  id = "scriptchess-state"
}

import {
  to = aws_s3_bucket.logs
  id = "scriptchess-logs"
}

import {
  to = aws_s3_bucket_policy.logs
  id = "scriptchess-logs"
}

import {
  to = aws_s3_bucket_public_access_block.logs
  id = "scriptchess-logs"
}

import {
  to = aws_s3_bucket_server_side_encryption_configuration.logs
  id = "scriptchess-logs"
}

import {
  to = aws_s3_bucket_ownership_controls.logs
  id = "scriptchess-logs"
}

import {
  to = aws_s3_bucket.generated_images
  id = "generated-images-scriptchess"
}

import {
  to = aws_s3_bucket_policy.generated_images
  id = "generated-images-scriptchess"
}

import {
  to = aws_s3_bucket_public_access_block.generated_images
  id = "generated-images-scriptchess"
}

import {
  to = aws_s3_bucket_server_side_encryption_configuration.generated_images
  id = "generated-images-scriptchess"
}

import {
  to = aws_s3_bucket_ownership_controls.generated_images
  id = "generated-images-scriptchess"
}
