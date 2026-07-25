variable "compartment_id" {
  description = "OCID of the compartment (tenancy) in which to create the budget."
  type        = string
}

variable "display_name" {
  description = "Human-readable name for the budget."
  type        = string
}

variable "description" {
  description = "Description of the budget."
  type        = string
  default     = null
}

variable "target_compartment_id" {
  description = "OCID of the compartment the budget tracks spend for."
  type        = string
}

variable "amount" {
  description = "Budget amount in the tenancy currency. Must be a whole number."
  type        = number

  validation {
    condition     = var.amount > 0
    error_message = "amount must be greater than zero."
  }

  # The Budgets API stores the amount "expressed as a whole number in the
  # currency of the customer's rate card", so a fractional amount is rejected
  # at apply time. Catch it during plan instead.
  validation {
    condition     = floor(var.amount) == var.amount
    error_message = "amount must be a whole number."
  }
}

variable "reset_period" {
  description = "How often the budget resets."
  type        = string
  default     = "MONTHLY"

  validation {
    condition     = contains(["MONTHLY"], var.reset_period)
    error_message = "reset_period must be MONTHLY."
  }
}

variable "alert_rules" {
  description = <<-EOT
    List of alert rules that notify recipients when thresholds are crossed.

    * `threshold`      - Value that triggers the alert. For `PERCENTAGE` this is a
                         percentage of `amount` (max 10000); for `ABSOLUTE` it is an
                         amount in the tenancy currency. Must be greater than zero.
    * `threshold_type` - `PERCENTAGE` (default) or `ABSOLUTE`.
    * `type`           - `ACTUAL` (default) alerts on spend already incurred;
                         `FORECAST` alerts on projected end-of-period spend.
    * `recipients`     - Delimited list of email addresses that receive the alert.
                         Delimiters may be a comma, semicolon, space or tab. Required
                         and must be non-empty: the Budgets API treats an empty string
                         as null, which creates an alert rule that notifies nobody.
    * `message`        - Optional custom message sent with the alert.
  EOT
  type = list(object({
    threshold      = number
    threshold_type = optional(string, "PERCENTAGE")
    type           = optional(string, "ACTUAL")
    recipients     = string
    message        = optional(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for r in var.alert_rules : contains(["PERCENTAGE", "ABSOLUTE"], r.threshold_type)
    ])
    error_message = "alert_rules[*].threshold_type must be PERCENTAGE or ABSOLUTE."
  }

  validation {
    condition = alltrue([
      for r in var.alert_rules : contains(["ACTUAL", "FORECAST"], r.type)
    ])
    error_message = "alert_rules[*].type must be ACTUAL or FORECAST."
  }

  validation {
    condition = alltrue([
      for r in var.alert_rules : r.threshold > 0
    ])
    error_message = "alert_rules[*].threshold must be greater than zero; a rule with a non-positive threshold never usefully fires."
  }

  # The Budgets API caps percentage thresholds at 10000.
  validation {
    condition = alltrue([
      for r in var.alert_rules : r.threshold <= 10000 if r.threshold_type == "PERCENTAGE"
    ])
    error_message = "alert_rules[*].threshold must be 10000 or less when threshold_type is PERCENTAGE."
  }

  # An alert rule with no recipients is accepted by the API ("an empty string is
  # interpreted as null") and then silently notifies nobody. Refuse it up front.
  validation {
    condition = alltrue([
      for r in var.alert_rules : trimspace(r.recipients) != ""
    ])
    error_message = "alert_rules[*].recipients must not be empty; an alert rule with no recipients notifies nobody."
  }

  validation {
    condition = alltrue(flatten([
      for r in var.alert_rules : [
        for address in regexall("[^,;[:space:]]+", r.recipients) :
        can(regex("^[^@[:space:]]+@[^@[:space:]]+\\.[^@[:space:]]+$", address))
      ]
    ]))
    error_message = "alert_rules[*].recipients must be email addresses delimited by a comma, semicolon, space or tab."
  }
}

variable "freeform_tags" {
  description = "Free-form tags applied to the budget."
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "Defined tags applied to the budget, keyed as \"namespace.key\"."
  type        = map(string)
  default     = {}
}
