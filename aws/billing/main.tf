# Billing alarms. Free: the first two budgets and Cost Anomaly Detection cost nothing.

variable "billing_email" {
  description = "Where budget and anomaly alerts are sent (set in aws/billing/terraform.tfvars)."
  type        = string

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+$", var.billing_email)) && !endswith(var.billing_email, "@example.com")
    error_message = "Set billing_email in aws/billing/terraform.tfvars to a real address."
  }
}

variable "monthly_budget_usd" {
  description = "Expected monthly AWS spend. Alerts at 80% (actual) and 100% (forecast)."
  type        = number
  default     = 10
}

resource "aws_budgets_budget" "monthly" {
  name         = "monthly-total"
  budget_type  = "COST"
  limit_amount = tostring(var.monthly_budget_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.billing_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.billing_email]
  }
}

# Catches a sudden spike (e.g. a leaked key used for mining) days before the monthly budget would.
# An account can have only one per-service monitor. If apply fails because one exists (AWS creates
# "Default-Services-Monitor" on some accounts), import it instead:
#   tofu import aws_ce_anomaly_monitor.services <monitor ARN from: aws ce get-anomaly-monitors>
resource "aws_ce_anomaly_monitor" "services" {
  name              = "services"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"
}

resource "aws_ce_anomaly_subscription" "daily" {
  name             = "daily-email"
  frequency        = "DAILY"
  monitor_arn_list = [aws_ce_anomaly_monitor.services.arn]

  subscriber {
    type    = "EMAIL"
    address = var.billing_email
  }

  # Alert when an anomaly's total impact is at least $5.
  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      match_options = ["GREATER_THAN_OR_EQUAL"]
      values        = ["5"]
    }
  }
}
