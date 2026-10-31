# The three buckets that are not a website or the image bucket: the OpenTofu state, access logs and generated
# images. Written to match what is live today, so the first plan shows no changes. Improvements go in a
# later change.
#
# Not here: the dev and prod site buckets (aws/envs), scriptchess-images (aws/media).

locals {
  region = "ap-south-1"
}

# ---------------------------------------------------------------- scriptchess-state

# Holds every state file of this repo, including this stack's own. It is imported here so its settings are
# written down, but it must never be destroyed or emptied: losing it loses the state of every stack.
resource "aws_s3_bucket" "state" {
  bucket        = "scriptchess-state"
  force_destroy = false

  tags = {
    purpose = "save-state"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_ownership_controls" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# ---------------------------------------------------------------- scriptchess-logs

resource "aws_s3_bucket" "logs" {
  bucket        = "scriptchess-logs"
  force_destroy = false

  lifecycle {
    prevent_destroy = true
  }
}

# There is no bucket policy. Until Oct 2026 one let anyone on the internet read and change the bucket's ACL
# (Principal "*", s3:GetBucketAcl / s3:PutBucketAcl). CloudFront log delivery does not need it: it writes through
# the ACL grant to the log delivery account, which AWS adds when logging is turned on. Removing the resource
# deletes the policy on the next apply.

# All four on. The log delivery grant is not public, so blocking public ACLs and policies does not stop logging.
resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Log delivery still uses ACLs, so the ownership has to stay BucketOwnerPreferred. The ACL itself (one extra
# full-control grant to the log delivery account) is not managed here: it is set by AWS when logging is turned on.
resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# ---------------------------------------------------------------- generated-images-scriptchess

resource "aws_s3_bucket" "generated_images" {
  bucket        = "generated-images-scriptchess"
  force_destroy = false

  lifecycle {
    prevent_destroy = true
  }
}

# Public read of every image, and of the bucket listing (the second resource is the bucket itself).
resource "aws_s3_bucket_policy" "generated_images" {
  bucket = aws_s3_bucket.generated_images.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "Stmt1405592139000"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource = [
        "${aws_s3_bucket.generated_images.arn}/*",
        aws_s3_bucket.generated_images.arn,
      ]
    }]
  })
}

resource "aws_s3_bucket_public_access_block" "generated_images" {
  bucket = aws_s3_bucket.generated_images.id

  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_server_side_encryption_configuration" "generated_images" {
  bucket = aws_s3_bucket.generated_images.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_ownership_controls" "generated_images" {
  bucket = aws_s3_bucket.generated_images.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}
