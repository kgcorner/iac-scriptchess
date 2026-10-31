# Who and what can act in the AWS account: three users, one group, and the role the EC2 instance uses. Written
# to match what is live today, so the first plan shows no changes. What should change is in HARDENING.md.
#
# Never managed here: access keys. A key made by OpenTofu would sit in the state file in plain text. Create,
# rotate and delete keys by hand (see HARDENING.md).
#
# Not here: rds-monitoring-role. There is no RDS database any more, so nothing needs it; delete it by hand.

locals {
  region = "ap-south-1"

  admin_group = "scriptchess-admin-group"

  managed = {
    admin           = "arn:aws:iam::aws:policy/AdministratorAccess"
    s3_full         = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
    cloudfront_full = "arn:aws:iam::aws:policy/CloudFrontFullAccess"
  }
}

# ---------------------------------------------------------------- group

# WARNING: every user below is in this group, and the group has AdministratorAccess. That includes deployer
# (the GitHub deploy credentials) and image-generator-user. See HARDENING.md before copying this pattern.
resource "aws_iam_group" "admin" {
  name = local.admin_group
}

resource "aws_iam_group_policy_attachment" "admin_administrator" {
  group      = aws_iam_group.admin.name
  policy_arn = local.managed.admin
}

resource "aws_iam_group_policy_attachment" "admin_s3" {
  group      = aws_iam_group.admin.name
  policy_arn = local.managed.s3_full
}

# ---------------------------------------------------------------- users

# You, at the console and the CLI.
resource "aws_iam_user" "admin" {
  name = "scriptchess-admin"

  lifecycle {
    prevent_destroy = true
  }
}

# The GitHub Actions deploy credentials (S3 upload and CloudFront invalidation).
resource "aws_iam_user" "deployer" {
  name = "deployer"

  lifecycle {
    prevent_destroy = true
  }
}

# Generates images into generated-images-scriptchess.
resource "aws_iam_user" "image_generator" {
  name = "image-generator-user"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_user_group_membership" "admin" {
  user   = aws_iam_user.admin.name
  groups = [aws_iam_group.admin.name]
}

resource "aws_iam_user_group_membership" "deployer" {
  user   = aws_iam_user.deployer.name
  groups = [aws_iam_group.admin.name]
}

resource "aws_iam_user_group_membership" "image_generator" {
  user   = aws_iam_user.image_generator.name
  groups = [aws_iam_group.admin.name]
}

resource "aws_iam_user_policy_attachment" "deployer_cloudfront" {
  user       = aws_iam_user.deployer.name
  policy_arn = local.managed.cloudfront_full
}

# ---------------------------------------------------------------- the EC2 instance's role

# The old application server (stopped for now). Full S3 access, which is more than it needs.
resource "aws_iam_role" "ec2_for_s3" {
  name                 = "ec2-for-s3"
  description          = "Allows EC2 instances to call S3 on your behalf."
  max_session_duration = 3600

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_for_s3" {
  role       = aws_iam_role.ec2_for_s3.name
  policy_arn = local.managed.s3_full
}

resource "aws_iam_instance_profile" "ec2_for_s3" {
  name = "ec2-for-s3"
  role = aws_iam_role.ec2_for_s3.name
}
