terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # One state file per stack, all in the same bucket.
  backend "s3" {
    bucket       = "scriptchess-state"
    key          = "aws/media.tfstate"
    region       = "ap-south-1"
    use_lockfile = true
    encrypt      = true
  }
}

provider "aws" {
  region = local.region # CloudFront is global; the region only picks where API calls go
}
