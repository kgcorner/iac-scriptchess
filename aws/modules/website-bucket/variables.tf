variable "bucket" {
  description = "Bucket name (also its website host, e.g. dev.scriptchess.com)."
  type        = string
}

variable "index_document" {
  type    = string
  default = "index.html"
}

variable "error_document" {
  description = "Document S3 returns for a missing key. CloudFront replaces the 404 with /404.html."
  type        = string
  default     = "index.html"
}
