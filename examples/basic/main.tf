provider "oci" {}

module "budget" {
  source = "../.."

  compartment_id        = var.tenancy_id
  display_name          = "example-budget"
  target_compartment_id = var.target_compartment_id
  amount                = 500

  alert_rules = [
    {
      threshold  = 80
      recipients = "finops@example.com"
      message    = "Budget has reached 80% of the monthly limit."
    },
    {
      threshold  = 100
      type       = "FORECAST"
      recipients = "finops@example.com,platform@example.com"
      message    = "Spend is forecast to exceed the monthly limit."
    }
  ]

  freeform_tags = {
    Environment = "sandbox"
    ManagedBy   = "terraform"
  }
}

variable "tenancy_id" {
  description = "Tenancy OCID in which to create the example budget."
  type        = string
}

variable "target_compartment_id" {
  description = "OCID of the compartment the example budget tracks."
  type        = string
}

output "budget_id" {
  value = module.budget.id
}
