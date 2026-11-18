locals {
  budget_alerts = {
    actual-50    = { type = "ACTUAL", percent = 50 }
    actual-80    = { type = "ACTUAL", percent = 80 }
    actual-100   = { type = "ACTUAL", percent = 100 }
    forecast-100 = { type = "FORECASTED", percent = 100 }
  }
}

# in the management account a budget covers every account in the organization
resource "aws_budgets_budget" "monthly" {
  name         = "minibank-monthly"
  budget_type  = "COST"
  limit_amount = tostring(var.monthly_budget_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  dynamic "notification" {
    for_each = local.budget_alerts

    content {
      notification_type          = notification.value.type
      comparison_operator        = "GREATER_THAN"
      threshold                  = notification.value.percent
      threshold_type             = "PERCENTAGE"
      subscriber_email_addresses = [var.alert_email]
    }
  }
}
