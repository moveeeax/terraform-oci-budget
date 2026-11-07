resource "oci_budget_budget" "this" {
  compartment_id = var.compartment_id
  display_name   = var.display_name
  description    = var.description

  # Scope. `target_compartment_id` is the shortcut for the common compartment
  # budget; `target` also covers budgets on a cost-tracking tag, which follow a
  # team or project across compartments. The precondition below requires exactly
  # one of the two.
  target_type = var.target != null ? var.target.type : "COMPARTMENT"
  targets     = var.target != null ? var.target.ids : [var.target_compartment_id]

  amount       = var.amount
  reset_period = var.reset_period

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags

  lifecycle {
    precondition {
      condition     = (var.target_compartment_id == null) != (var.target == null)
      error_message = "Set exactly one of target_compartment_id (budget on a compartment) or target (budget on a compartment or a cost-tracking tag)."
    }
  }
}

resource "oci_budget_alert_rule" "this" {
  count = length(var.alert_rules)

  budget_id      = oci_budget_budget.this.id
  type           = var.alert_rules[count.index].type
  threshold      = var.alert_rules[count.index].threshold
  threshold_type = var.alert_rules[count.index].threshold_type
  recipients     = var.alert_rules[count.index].recipients
  message        = var.alert_rules[count.index].message
}
