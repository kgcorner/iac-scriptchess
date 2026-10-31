# Billing alarms

Budget `monthly-total` and a Cost Anomaly Detection monitor + daily email. All free.

Set `billing_email` in `terraform.tfvars` first (the placeholder is rejected).

## Only if these were already applied from `aws/storage`

They already exist in AWS, so import them instead of creating duplicates (run in this folder after `tofu init`):

```bash
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
tofu import aws_budgets_budget.monthly "$ACCOUNT:monthly-total"
tofu import aws_ce_anomaly_monitor.services \
  "$(aws ce get-anomaly-monitors --query 'AnomalyMonitors[?MonitorName==`services`].MonitorArn' --output text)"
tofu import aws_ce_anomaly_subscription.daily \
  "$(aws ce get-anomaly-subscriptions --query 'AnomalySubscriptions[?SubscriptionName==`daily-email`].SubscriptionArn' --output text)"
```

Then `tofu plan` should show no changes.
