# Adopt the existing zone and its records. Delete this file after the first successful apply.

locals {
  zone_id = "Z0794218UM60ESHGZL1C"
}

import {
  to = aws_route53_zone.main
  id = local.zone_id
}

# <zone id>_<record name>_<type>
import {
  for_each = local.records
  to       = aws_route53_record.this[each.key]
  id       = "${local.zone_id}_${each.value.name}_${each.value.type}"
}
