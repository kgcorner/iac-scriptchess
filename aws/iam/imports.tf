# Adopt the existing IAM. Delete this file after the first successful apply.

import {
  to = aws_iam_group.admin
  id = "scriptchess-admin-group"
}

import {
  to = aws_iam_group_policy_attachment.admin_administrator
  id = "scriptchess-admin-group/arn:aws:iam::aws:policy/AdministratorAccess"
}

import {
  to = aws_iam_group_policy_attachment.admin_s3
  id = "scriptchess-admin-group/arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

import {
  to = aws_iam_user.admin
  id = "scriptchess-admin"
}

import {
  to = aws_iam_user.deployer
  id = "deployer"
}

import {
  to = aws_iam_user.image_generator
  id = "image-generator-user"
}

import {
  to = aws_iam_user_group_membership.admin
  id = "scriptchess-admin/scriptchess-admin-group"
}

import {
  to = aws_iam_user_group_membership.deployer
  id = "deployer/scriptchess-admin-group"
}

import {
  to = aws_iam_user_group_membership.image_generator
  id = "image-generator-user/scriptchess-admin-group"
}

import {
  to = aws_iam_user_policy_attachment.deployer_cloudfront
  id = "deployer/arn:aws:iam::aws:policy/CloudFrontFullAccess"
}

import {
  to = aws_iam_role.ec2_for_s3
  id = "ec2-for-s3"
}

import {
  to = aws_iam_role_policy_attachment.ec2_for_s3
  id = "ec2-for-s3/arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

import {
  to = aws_iam_instance_profile.ec2_for_s3
  id = "ec2-for-s3"
}
