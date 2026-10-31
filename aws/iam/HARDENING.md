# Clearing out the old IAM

State of the account on 31 Oct 2026, and what to do about it. Nothing here is done by OpenTofu: access keys
must never be in the state file, and removing the old users before the deploy has moved would break it.

## Today

- Group `scriptchess-admin-group` has `AdministratorAccess` and `AmazonS3FullAccess`, and contains **all three
  users**: `scriptchess-admin`, `deployer`, `image-generator-user`. Every key is a full administrator key.
- `deployer` has two active keys (2024, 2026) and CloudFront full access; its key is in GitHub as a secret.
- `scriptchess-admin` has a key from 2022. It was last used on 2026-10-01 against S3 and the owner does not
  know by what. CloudTrail's event history shows nothing for it, which fits: object reads and writes are data
  events, which are not recorded unless a trail is set up for them.
- `image-generator-user` has a key from 2025.
- Nobody has MFA.
- Roles `ec2-for-s3` (full S3) and `rds-monitoring-role` (no RDS database exists any more).

## Target

Only deployment needs AWS from outside: the two `github-deploy-*` roles in `main.tf`. Everything else is a
person using the console or CLI, with MFA. No IAM user holds a key.

## Order (each step is checked before the next)

1. Apply this stack (creates the OIDC provider and two roles; changes nothing that exists).
2. In scriptchess-fe, change the workflows to assume the roles (`aws-actions/configure-aws-credentials`) and
   run a dev deploy. Then a prod run once `DEPLOY_ENABLED` is on.
2b. Apply, then `aws iam create-access-key --user-name strapi-media`, put the key in the Strapi droplets' env
   files, restart Strapi, upload one image to confirm. `scriptchess-admin` (used by Strapi) was deactivated early,
   so uploads are broken until this is done.
3. Deactivate (do not delete) every access key of the three users. Wait a week. If nothing broke, delete them.
4. Delete the three users and the group, and the `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` secrets in GitHub.
5. Delete `ec2-for-s3` (and its instance profile) when the stopped instance is deleted, and `rds-monitoring-role` now.
6. Make sure your own login has MFA (the root user too).
