output "distribution_id" {
  value = aws_cloudfront_distribution.this.id
}

output "domain_name" {
  value = aws_cloudfront_distribution.this.domain_name
}

output "function_arn" {
  value = aws_cloudfront_function.viewer_request.arn
}
