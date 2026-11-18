variable "alert_email" {
  description = "Email that receives budget alerts"
  type        = string
}

variable "workload_account_email" {
  description = "Root email of the workload account"
  type        = string
}

variable "monthly_budget_usd" {
  description = "Monthly cost limit for the whole organization"
  type        = number
  default     = 40
}
