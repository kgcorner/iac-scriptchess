# One static-site distribution: S3 website origin, a viewer-request function, security headers,
# and a real 404 for unknown URLs.

# AWS-managed policy: caches on path only (query strings, cookies and headers are not part of the key
# and not sent to S3), and enables gzip/brotli. The app reads query strings in the browser, so the
# origin never needs them.
data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

resource "aws_cloudfront_function" "viewer_request" {
  name    = "${var.name}-viewer-request"
  runtime = "cloudfront-js-2.0"
  comment = "www strip, legacy redirects, client-only routes"
  publish = true
  code    = file(var.function_file)
}

resource "aws_cloudfront_response_headers_policy" "security" {
  name    = "${var.name}-security-headers"
  comment = "Security headers for ${var.name}"

  security_headers_config {
    content_type_options {
      override = true
    }

    frame_options {
      frame_option = "SAMEORIGIN"
      override     = true
    }

    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }

    dynamic "strict_transport_security" {
      for_each = var.hsts ? [1] : []
      content {
        access_control_max_age_sec = 31536000
        include_subdomains         = false
        preload                    = false
        override                   = true
      }
    }
  }
}

resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  is_ipv6_enabled     = true
  http_version        = "http2"
  aliases             = var.aliases
  default_root_object = var.default_root_object
  price_class         = var.price_class
  comment             = var.name
  tags                = var.tags

  origin {
    origin_id   = var.origin_id
    domain_name = var.origin_domain

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "http-only" # S3 website endpoints do not speak HTTPS
      origin_ssl_protocols     = ["TLSv1.2"]
      origin_read_timeout      = 30
      origin_keepalive_timeout = 5
    }
  }

  default_cache_behavior {
    target_origin_id           = var.origin_id
    viewer_protocol_policy     = "redirect-to-https" # http:// gets a 301 to https://
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    cache_policy_id            = data.aws_cloudfront_cache_policy.caching_optimized.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security.id

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.viewer_request.arn
    }
  }

  # A missing file is a real 404, not the app shell with status 200.
  custom_error_response {
    error_code            = 404
    response_code         = 404
    response_page_path    = "/404.html"
    error_caching_min_ttl = 10
  }

  dynamic "logging_config" {
    for_each = var.logging_bucket == null ? [] : [1]
    content {
      bucket          = var.logging_bucket
      include_cookies = false
      prefix          = var.logging_prefix
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}
