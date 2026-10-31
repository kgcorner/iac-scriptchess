# How GitHub Actions deploys, with no AWS keys stored in GitHub.
#
# A workflow asks AWS for short-lived credentials (OIDC) by proving which repository and branch it runs from.
# Each role can touch one site only, and the prod role can only be assumed from the master branch.
#
# What is deliberately not here: IAM users and access keys (a key made by OpenTofu would sit in the state in
# plain text), and the old roles for EC2 and RDS. See HARDENING.md for the clean-up of what exists today.

locals {
  region = "ap-south-1"

  repo = "kgcorner/scriptchess-fe"

  sites = {
    dev = {
      bucket          = "dev.scriptchess.com"
      distribution_id = "E5RDYG73D1FLN"
      # Dev deploys can be started by hand from any branch. Pull requests (including from forks) cannot assume it.
      subjects = ["repo:${local.repo}:ref:refs/heads/*"]
    }
    prod = {
      # Prod serves the www.scriptchess.com bucket today while deploys write to scriptchess.com. Add that bucket
      # here when the bucket question is settled.
      bucket          = "scriptchess.com"
      distribution_id = "E1VV4H17VBT521"
      subjects        = ["repo:${local.repo}:ref:refs/heads/master"]
    }
  }
}

data "aws_caller_identity" "current" {}

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  # AWS no longer checks the thumbprint for GitHub, but older provider versions require one.
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd",
  ]
}

resource "aws_iam_role" "deploy" {
  for_each = local.sites

  name                 = "github-deploy-${each.key}"
  description          = "GitHub Actions deploys of ${each.value.bucket} (no keys)."
  max_session_duration = 3600

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = { "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com" }
        StringLike   = { "token.actions.githubusercontent.com:sub" = each.value.subjects }
      }
    }]
  })
}

# Exactly what scripts/deploy-s3.js, prune-stale-assets.js and incremental-articles.js do, on one site.
resource "aws_iam_role_policy" "deploy" {
  for_each = local.sites

  name = "deploy-${each.key}"
  role = aws_iam_role.deploy[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ListTheBucket"
        Effect   = "Allow"
        Action   = ["s3:ListBucket", "s3:GetBucketLocation"]
        Resource = "arn:aws:s3:::${each.value.bucket}"
      },
      {
        Sid      = "ReadWriteDeleteObjects"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "arn:aws:s3:::${each.value.bucket}/*"
      },
      {
        Sid      = "InvalidateTheCache"
        Effect   = "Allow"
        Action   = ["cloudfront:GetDistribution", "cloudfront:CreateInvalidation", "cloudfront:GetInvalidation"]
        Resource = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${each.value.distribution_id}"
      },
    ]
  })
}
