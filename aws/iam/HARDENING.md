# IAM hardening (not applied)

`main.tf` copies what is live today. This is what is wrong with it, in order of risk. Nothing here is done
by OpenTofu: access keys must never be in the state file, and changing the group would cut off the deploy.

## 1. Every user is an administrator

`scriptchess-admin-group` has `AdministratorAccess` and contains all three users. A leaked GitHub secret
(`deployer`) or image-generator key can read, change or delete anything in the account, including billing,
IAM and the state bucket.

Target:

| User | Needs | Give it |
|---|---|---|
| `scriptchess-admin` | everything | stays in the admin group, with MFA |
| `deployer` | upload to `scriptchess.com` and `dev.scriptchess.com`; CloudFront invalidation | a policy with `s3:ListBucket`, `s3:GetObject`, `s3:PutObject`, `s3:DeleteObject` on those two buckets, and `cloudfront:GetDistribution`, `cloudfront:CreateInvalidation`, `cloudfront:GetInvalidation` |
| `image-generator-user` | write to `generated-images-scriptchess` | `s3:PutObject`, `s3:GetObject`, `s3:ListBucket` on that bucket |

Order: write the two policies, attach them, test a deploy and an image run, then remove both users from the
admin group. Never the other way round.

## 2. Keys

- `deployer` has **two active keys** (2024 and 2026). Find which one GitHub uses (the repository secret
  `AWS_ACCESS_KEY_ID`), then deactivate the other for a week and delete it.
- `scriptchess-admin` has a key from **2022**. Create a new one, switch your CLI over, then delete the old one.
- `image-generator-user` key (2025): rotate yearly.

## 3. MFA

No user has MFA. Turn it on for `scriptchess-admin` first (IAM, Users, Security credentials). Better still, use
`aws login` or IAM Identity Center for your own access and keep this user for emergencies.

## 4. The EC2 role

`ec2-for-s3` has full S3 access. The instance is stopped. When it is deleted, delete the role and instance
profile with it (remove them from `main.tf` and apply).

## 5. Leftovers

`rds-monitoring-role` belongs to an RDS database that no longer exists. Delete it by hand.
