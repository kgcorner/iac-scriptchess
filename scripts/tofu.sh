#!/usr/bin/env bash
# Runs tofu with credentials from your current AWS CLI login (`aws login` or `aws sso login`).
# The AWS provider cannot read `aws login` sessions itself, which fails with
# "No valid credential sources found". This exports temporary keys for this one command only;
# nothing is written to disk and your shell is left unchanged.
#
# Usage, from any stack folder:   ../../../scripts/tofu.sh plan -out=dev.tfplan
# Other profile:                  AWS_PROFILE=other ../../../scripts/tofu.sh plan
set -euo pipefail

profile="${AWS_PROFILE:-default}"

if ! command -v aws >/dev/null 2>&1; then
  echo "aws CLI not found" >&2
  exit 1
fi

if ! aws sts get-caller-identity --profile "$profile" >/dev/null 2>&1; then
  echo "Not logged in for profile '$profile'. Run 'aws login' (or 'aws sso login --profile $profile') first." >&2
  exit 1
fi

creds="$(aws configure export-credentials --profile "$profile" --format env)"
unset AWS_PROFILE
eval "$creds"
exec tofu "$@"
