# The image bucket and the CloudFront distribution in front of it. Written to match what is live today,
# so the first plan shows no changes. Improvements go in a later change.

locals {
  region = "ap-south-1"
  bucket = "scriptchess-images"

  # "COEP-with-require-corp", a hand-made policy shared with the dev and prod site distributions
  # (COOP/COEP/CORP headers plus an expired origin-trial token). Not managed here yet: prod pages still
  # send COEP, so these images must keep their CORP/CORS headers until prod is migrated. Then replace it.
  response_headers_policy_id = "a0d5d361-8527-4d04-a303-e76b29cbce9a"
}

# ---------------------------------------------------------------- bucket

resource "aws_s3_bucket" "media" {
  bucket        = local.bucket
  force_destroy = false

  # Deleting the bucket would delete every image.
  lifecycle {
    prevent_destroy = true
  }
}

# Public read. There is deliberately no public access block resource: none is configured today.
resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.media.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.media.arn}/*"
    }]
  })
}

resource "aws_s3_bucket_cors_configuration" "media" {
  bucket = aws_s3_bucket.media.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "media" {
  bucket = aws_s3_bucket.media.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = false
  }
}

resource "aws_s3_bucket_ownership_controls" "media" {
  bucket = aws_s3_bucket.media.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# ---------------------------------------------------------------- distribution

# AWS-managed policy: caches on path only and enables compression.
data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

resource "aws_cloudfront_distribution" "media" {
  enabled         = true
  is_ipv6_enabled = true
  http_version    = "http2"
  price_class     = "PriceClass_All"

  origin {
    origin_id   = "${local.bucket}.s3.${local.region}.amazonaws.com"
    domain_name = "${local.bucket}.s3.${local.region}.amazonaws.com"

    # The bucket is public, so there is no origin access identity or control.
    s3_origin_config {
      origin_access_identity = ""
    }
  }

  default_cache_behavior {
    target_origin_id           = "${local.bucket}.s3.${local.region}.amazonaws.com"
    viewer_protocol_policy     = "redirect-to-https"
    allowed_methods            = ["GET", "HEAD"]
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    cache_policy_id            = data.aws_cloudfront_cache_policy.caching_optimized.id
    response_headers_policy_id = local.response_headers_policy_id
  }

  # No custom domain: images are served from the distribution's own *.cloudfront.net name.
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Deleting this would change the image URLs the app uses.
  lifecycle {
    prevent_destroy = true
  }
}

output "distribution_id" {
  value = aws_cloudfront_distribution.media.id
}

output "domain_name" {
  value = aws_cloudfront_distribution.media.domain_name
}
