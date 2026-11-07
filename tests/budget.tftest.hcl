# Requires Terraform >= 1.7 (or OpenTofu >= 1.7) for `mock_provider`.
# The module itself still supports >= 1.5 — this is a test-only requirement.
# No OCI credentials and no network access are needed to run these.

mock_provider "oci" {}

variables {
  compartment_id        = "ocid1.tenancy.oc1..aaaaaaaaexampletenancy"
  display_name          = "unit-test-budget"
  target_compartment_id = "ocid1.compartment.oc1..aaaaaaaaexamplecompartment"
  amount                = 500
}

run "budget_defaults" {
  command = plan

  assert {
    condition     = oci_budget_budget.this.reset_period == "MONTHLY"
    error_message = "Budget must reset monthly, the only period the Budgets API supports."
  }

  # target_compartment_id on oci_budget_budget is deprecated; the budget must be
  # scoped through target_type/targets instead.
  assert {
    condition     = oci_budget_budget.this.target_type == "COMPARTMENT"
    error_message = "Budget must be targeted at a compartment via target_type."
  }

  assert {
    condition     = oci_budget_budget.this.targets == tolist([var.target_compartment_id])
    error_message = "Budget must target exactly the requested compartment; the API accepts exactly one target."
  }

  assert {
    condition     = length(oci_budget_alert_rule.this) == 0
    error_message = "No alert rules should be created when alert_rules is left at its default."
  }
}

run "alert_rule_defaults" {
  command = plan

  variables {
    alert_rules = [
      {
        threshold  = 80
        recipients = "finops@example.com"
      }
    ]
  }

  assert {
    condition     = oci_budget_alert_rule.this[0].type == "ACTUAL"
    error_message = "An alert rule must default to alerting on ACTUAL spend."
  }

  assert {
    condition     = oci_budget_alert_rule.this[0].threshold_type == "PERCENTAGE"
    error_message = "An alert rule must default to a PERCENTAGE threshold."
  }

  assert {
    condition     = oci_budget_alert_rule.this[0].recipients == "finops@example.com"
    error_message = "Recipients must be passed through to the alert rule unchanged."
  }
}

run "forecast_and_absolute_rules_are_accepted" {
  command = plan

  variables {
    alert_rules = [
      {
        threshold      = 100
        threshold_type = "PERCENTAGE"
        type           = "FORECAST"
        recipients     = "finops@example.com,platform@example.com"
        message        = "Forecast spend will exceed the budget."
      },
      {
        threshold      = 4500
        threshold_type = "ABSOLUTE"
        type           = "ACTUAL"
        recipients     = "finops@example.com; oncall@example.com"
      }
    ]
  }

  assert {
    condition     = length(oci_budget_alert_rule.this) == 2
    error_message = "Both alert rules should be created."
  }

  assert {
    condition     = oci_budget_alert_rule.this[0].type == "FORECAST"
    error_message = "FORECAST alert rules must be passed through as FORECAST."
  }

  assert {
    condition     = oci_budget_alert_rule.this[1].threshold_type == "ABSOLUTE"
    error_message = "ABSOLUTE alert rules must be passed through as ABSOLUTE."
  }
}

# An empty recipients string is accepted by the Budgets API ("an empty string is
# interpreted as null") and produces an alert rule that notifies nobody.
run "rejects_empty_recipients" {
  command = plan

  variables {
    alert_rules = [
      {
        threshold  = 80
        recipients = ""
      }
    ]
  }

  expect_failures = [var.alert_rules]
}

run "rejects_whitespace_only_recipients" {
  command = plan

  variables {
    alert_rules = [
      {
        threshold  = 80
        recipients = "   "
      }
    ]
  }

  expect_failures = [var.alert_rules]
}

run "rejects_malformed_recipient_address" {
  command = plan

  variables {
    alert_rules = [
      {
        threshold  = 80
        recipients = "finops@example.com,not-an-email"
      }
    ]
  }

  expect_failures = [var.alert_rules]
}

run "rejects_invalid_alert_type" {
  command = plan

  variables {
    alert_rules = [
      {
        threshold  = 80
        type       = "PREDICTED"
        recipients = "finops@example.com"
      }
    ]
  }

  expect_failures = [var.alert_rules]
}

run "rejects_invalid_threshold_type" {
  command = plan

  variables {
    alert_rules = [
      {
        threshold      = 80
        threshold_type = "RELATIVE"
        recipients     = "finops@example.com"
      }
    ]
  }

  expect_failures = [var.alert_rules]
}

run "rejects_non_positive_threshold" {
  command = plan

  variables {
    alert_rules = [
      {
        threshold  = 0
        recipients = "finops@example.com"
      }
    ]
  }

  expect_failures = [var.alert_rules]
}

run "rejects_percentage_threshold_above_api_maximum" {
  command = plan

  variables {
    alert_rules = [
      {
        threshold      = 10001
        threshold_type = "PERCENTAGE"
        recipients     = "finops@example.com"
      }
    ]
  }

  expect_failures = [var.alert_rules]
}

run "rejects_non_positive_amount" {
  command = plan

  variables {
    amount = 0
  }

  expect_failures = [var.amount]
}

run "rejects_fractional_amount" {
  command = plan

  variables {
    amount = 500.5
  }

  expect_failures = [var.amount]
}

# --- target: compartment or cost-tracking tag ----------------------------------

run "tag_targeted_budget" {
  command = plan

  variables {
    target_compartment_id = null
    target = {
      type = "TAG"
      ids  = ["CostTracking.Project.checkout"]
    }
  }

  assert {
    condition     = oci_budget_budget.this.target_type == "TAG"
    error_message = "A tag budget must be sent with target_type TAG."
  }

  assert {
    condition     = oci_budget_budget.this.targets == tolist(["CostTracking.Project.checkout"])
    error_message = "The cost-tracking tag must be passed through as the single target."
  }
}

run "compartment_target_object" {
  command = plan

  variables {
    target_compartment_id = null
    target = {
      type = "COMPARTMENT"
      ids  = ["ocid1.compartment.oc1..aaaaaaaaothercompartment"]
    }
  }

  assert {
    condition     = oci_budget_budget.this.target_type == "COMPARTMENT"
    error_message = "A compartment target object must be sent with target_type COMPARTMENT."
  }

  assert {
    condition     = oci_budget_budget.this.targets == tolist(["ocid1.compartment.oc1..aaaaaaaaothercompartment"])
    error_message = "The compartment OCID from target.ids must be passed through."
  }
}

run "rejects_target_and_target_compartment_id_together" {
  command = plan

  variables {
    target = {
      type = "TAG"
      ids  = ["CostTracking.Project.checkout"]
    }
  }

  expect_failures = [oci_budget_budget.this]
}

run "rejects_missing_target" {
  command = plan

  variables {
    target_compartment_id = null
  }

  expect_failures = [oci_budget_budget.this]
}

run "rejects_invalid_target_type" {
  command = plan

  variables {
    target_compartment_id = null
    target = {
      type = "PROJECT"
      ids  = ["CostTracking.Project.checkout"]
    }
  }

  expect_failures = [var.target]
}

run "rejects_multiple_targets" {
  command = plan

  variables {
    target_compartment_id = null
    target = {
      type = "TAG"
      ids  = ["CostTracking.Project.checkout", "CostTracking.Project.search"]
    }
  }

  expect_failures = [var.target]
}

run "rejects_malformed_tag_target" {
  command = plan

  variables {
    target_compartment_id = null
    target = {
      type = "TAG"
      ids  = ["CostTracking.Project"]
    }
  }

  expect_failures = [var.target]
}

run "rejects_tag_passed_as_compartment" {
  command = plan

  variables {
    target_compartment_id = null
    target = {
      type = "COMPARTMENT"
      ids  = ["CostTracking.Project.checkout"]
    }
  }

  expect_failures = [var.target]
}
