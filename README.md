# iac-scriptchess

Infrastructure for ScriptChess, managed with [OpenTofu](https://opentofu.org). Private repo. It starts with CloudFront; other resources move in over time.

## Layout

```
aws/cloudfront/
  modules/site/     one distribution: S3 website origin, function, security headers, 404 page
  functions/        viewer-request.js (+ tests), shared by dev and prod
  dev/              dev.scriptchess.com
  prod/             scriptchess.com, www.scriptchess.com
```

Dev and prod live in one AWS account, so they are kept apart by **separate state files** (`scriptchess-state` bucket, keys `cloudfront/dev.tfstate` and `cloudfront/prod.tfstate`) and separate folders. Both call the same module, so they cannot drift.

## Rules

- Run `tofu plan` before every apply and read it. Apply dev first, check it, then prod.
- CI never applies. It only checks format, validity and the function tests.
- Never commit state, credentials or `*.tfvars` other than `terraform.tfvars` (ids only).

## Prod is frozen

Nothing in `prod/` runs unless you pass `-var confirm_prod_change=yes-change-prod`, and its `distribution_id` is still `REPLACE_ME`. Until both are done on purpose, prod cannot be planned or changed from this repo. Dev is unaffected: applying dev only touches the dev distribution and creates a new dev function; the old shared functions stay as they are, so prod keeps running exactly as today.

## What the distributions do

- **HTTP to HTTPS:** `redirect-to-https` on the behaviour (CloudFront answers 301). Prod also has HSTS available (`hsts` in `main.tf`, off until prod has run on HTTPS only for a while).
- **Query strings:** not sent to S3 and not part of the cache key (the app reads them in the browser). The function keeps them across its redirects.
- **404:** a missing file returns `/404.html` with status 404 (not the app shell with 200).
- **Function** (`functions/viewer-request.js`): strips `www`, redirects legacy routes (301), and serves client-rendered routes the app shell. Update `CLIENT_ONLY` from `npm run cloudfront:allowlist` in scriptchess-fe when client-only routes change.
- Deploys must still invalidate CloudFront (the frontend workflows already do).

## First time: adopt the existing distributions

The distributions already exist, so they are **imported**, not created.

1. `aws cloudfront list-distributions --query "DistributionList.Items[].[Id,Aliases.Items[0]]" --output text` and put the ids in `dev/terraform.tfvars` and `prod/terraform.tfvars`. (Not the ETag from `get-distribution-config`.)
2. `cd aws/cloudfront/dev && tofu init && tofu plan`.
3. Expected: the function and security-headers policy are **created**; the distribution is **updated in place** (the old functions and policies are detached; they stay in the account until you delete them). Anything else, stop and read it.
4. `tofu apply`. The rollout takes about 5 to 15 minutes. Then check dev (below).
5. Repeat in `prod/`, after answering the open question in `prod/main.tf`.
6. Delete the `import` block after the first successful apply.

Test the function without deploying: `aws cloudfront test-function --name scriptchess-dev-viewer-request --if-match <ETag> --event-object fileb://event.json`.

### Check after applying

```
curl -sI http://dev.scriptchess.com/        # 301 to https
curl -sI "https://dev.scriptchess.com/pages/contact-us?a=1"   # 301 to /about?a=1
curl -sI https://dev.scriptchess.com/no-such-page             # 404
curl -sI https://dev.scriptchess.com/insight/abc              # 200 (app shell)
```

## Local tests

```
node --test aws/cloudfront/functions/viewer-request.test.js
tofu fmt -recursive
```

## Costs

OpenTofu is free. State storage is a few cents a month. CloudFront Functions: 2M invocations a month free, then $0.10 per million. The new policies and the 404 page cost nothing extra.
