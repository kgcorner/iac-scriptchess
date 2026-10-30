variable "distribution_id" {
  description = "Id of the existing distribution (aws cloudfront list-distributions)."
  type        = string
}

# Prod is frozen until the open questions in main.tf are answered. Every plan and apply in this folder
# fails unless this is set on purpose, e.g. `tofu plan -var confirm_prod_change=yes-change-prod`.
variable "confirm_prod_change" {
  description = "Must be yes-change-prod to run anything against prod."
  type        = string
  default     = "frozen"

  validation {
    condition     = var.confirm_prod_change == "yes-change-prod"
    error_message = "Prod is frozen. Set confirm_prod_change=yes-change-prod only when you mean to change the live distribution."
  }
}
