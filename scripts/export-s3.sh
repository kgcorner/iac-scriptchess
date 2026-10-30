#!/usr/bin/env bash
# Prints every setting of an S3 bucket that this repo may need to manage, one labelled section each.
# Read-only. A setting that is not configured prints its "does not exist" error; that is expected and
# tells us to leave it out of the code.
#
# Usage:  ./scripts/export-s3.sh scriptchess-images > scriptchess-images.log
set -uo pipefail

bucket="${1:?usage: export-s3.sh <bucket>}"

run() {
  local label="$1"
  shift
  echo "=== $label"
  "$@" 2>&1 || true
  echo
}

run location aws s3api get-bucket-location --bucket "$bucket"
run versioning aws s3api get-bucket-versioning --bucket "$bucket"
run website aws s3api get-bucket-website --bucket "$bucket"
run policy aws s3api get-bucket-policy --bucket "$bucket"
run public-access-block aws s3api get-public-access-block --bucket "$bucket"
run cors aws s3api get-bucket-cors --bucket "$bucket"
run tagging aws s3api get-bucket-tagging --bucket "$bucket"
run encryption aws s3api get-bucket-encryption --bucket "$bucket"
run lifecycle aws s3api get-bucket-lifecycle-configuration --bucket "$bucket"
run ownership-controls aws s3api get-bucket-ownership-controls --bucket "$bucket"
run logging aws s3api get-bucket-logging --bucket "$bucket"
run acl aws s3api get-bucket-acl --bucket "$bucket"
