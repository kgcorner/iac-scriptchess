terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # State lives in S3, one file per environment. Locking uses S3's own lock file.
  backend "s3" {
    bucket       = "scriptchess-state"
    key          = "aws/prod.tfstate"
    region       = "ap-south-1"
    use_lockfile = true
    encrypt      = true
  }
}

provider "aws" {
  region = "ap-south-1" # CloudFront is global; the region only picks where API calls go
}
