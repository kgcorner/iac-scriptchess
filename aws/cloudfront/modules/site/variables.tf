variable "name" {
  description = "Short name used for the function and policy, e.g. scriptchess-prod."
  type        = string
}

variable "aliases" {
  description = "Domain names served by the distribution."
  type        = list(string)
}

variable "origin_id" {
  description = "Id of the origin inside the distribution."
  type        = string
}

variable "origin_domain" {
  description = "S3 website endpoint, e.g. dev.scriptchess.com.s3-website.ap-south-1.amazonaws.com."
  type        = string
}

variable "certificate_arn" {
  description = "ACM certificate in us-east-1 covering every alias."
  type        = string
}

variable "function_file" {
  description = "Path to the viewer-request function source."
  type        = string
}

variable "hsts" {
  description = "Send Strict-Transport-Security. Browsers then refuse plain HTTP for a year, so turn it on only once HTTPS works everywhere."
  type        = bool
  default     = false
}

variable "logging_bucket" {
  description = "Bucket domain for access logs (e.g. scriptchess-logs.s3.amazonaws.com), or null for none."
  type        = string
  default     = null
}

variable "logging_prefix" {
  type    = string
  default = ""
}

variable "default_root_object" {
  type    = string
  default = "index.html"
}

variable "price_class" {
  type    = string
  default = "PriceClass_All"
}

variable "tags" {
  type    = map(string)
  default = {}
}
