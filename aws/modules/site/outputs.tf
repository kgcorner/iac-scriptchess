output "distribution_id" {
  value = aws_cloudfront_distribution.this.id
}

output "domain_name" {
  value = aws_cloudfront_distribution.this.domain_name
}

output "function_arn" {
  value = aws_cloudfront_function.viewer_request.arn
}

output "hosted_zone_id" {
  description = "Route 53 zone id of CloudFront, needed for alias records."
  value       = aws_cloudfront_distribution.this.hosted_zone_id
}
