# Things shared by every environment: the scriptchess.com DNS zone and the records in it that no single
# environment owns. Written to match what is live, so the first plan shows no changes.
#
# Not here on purpose:
#   - NS and SOA at the apex: Route 53 creates and maintains them with the zone.
#   - dev.scriptchess.com (A): owned by aws/envs/dev.
#   - scriptchess.com and www.scriptchess.com (A, to the prod CloudFront): will be owned by aws/envs/prod.

resource "aws_route53_zone" "main" {
  name    = "scriptchess.com"
  comment = "DNS Entries for scriptchess.com"

  # Deleting the zone would take the whole site, mail and API offline.
  lifecycle {
    prevent_destroy = true
  }
}
