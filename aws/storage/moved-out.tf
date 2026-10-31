# The billing alarms moved to aws/billing. If they were ever applied from this stack, these blocks drop them
# from this state WITHOUT deleting them in AWS; import them into aws/billing (see the README there).
# If they were never applied, these blocks do nothing. Delete this file once both stacks are applied.

removed {
  from = aws_budgets_budget.monthly
  lifecycle {
    destroy = false
  }
}

removed {
  from = aws_ce_anomaly_monitor.services
  lifecycle {
    destroy = false
  }
}

removed {
  from = aws_ce_anomaly_subscription.daily
  lifecycle {
    destroy = false
  }
}
