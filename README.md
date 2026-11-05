# terraform-oci-budget

Terraform module that manages an [Oracle Cloud Infrastructure](https://www.oracle.com/cloud/)
Budget that tracks spend for a target compartment, along with any number of alert rules
that email recipients when actual or forecast spend crosses a threshold.

## Usage

```hcl
module "budget" {
  source = "github.com/moveeeax/terraform-oci-budget?ref=v1.0.0"

  compartment_id        = var.tenancy_id
  display_name          = "prod-budget"
  target_compartment_id = var.prod_compartment_id
  amount                = 5000

  alert_rules = [
    {
      threshold  = 90
      recipients = "finops@example.com"
    },
    {
      threshold  = 100
      type       = "FORECAST"
      recipients = "finops@example.com,platform@example.com"
    }
  ]

  freeform_tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

A runnable example lives in [`examples/basic`](examples/basic).

## Alert rules

Each element of `alert_rules` is an object with these attributes:

| Attribute        | Type     | Default        | Description                                                                                                                                                                       |
|------------------|----------|----------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `threshold`      | `number` | n/a (required) | Value that triggers the alert. Must be greater than zero. For `PERCENTAGE` this is a percentage of `amount` and may not exceed `10000`; for `ABSOLUTE` it is an amount in the tenancy currency. |
| `threshold_type` | `string` | `"PERCENTAGE"` | `PERCENTAGE` or `ABSOLUTE`.                                                                                                                                                        |
| `type`           | `string` | `"ACTUAL"`     | `ACTUAL` alerts on spend already incurred; `FORECAST` alerts on projected end-of-period spend.                                                                                      |
| `recipients`     | `string` | n/a (required) | Email addresses that receive the alert, delimited by a comma, semicolon, space or tab.                                                                                              |
| `message`        | `string` | `null`         | Custom message sent with the alert. OCI supplies a default message when omitted.                                                                                                    |

`recipients` is optional in the Budgets API, and an empty string there is interpreted
as null — producing an alert rule that triggers but notifies nobody. This module
therefore requires `recipients` and rejects an empty or whitespace-only value at plan
time.

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.5   |
| oci       | >= 5.0   |

## Inputs

| Name                    | Description                                                        | Type                | Default     | Required |
|-------------------------|--------------------------------------------------------------------|---------------------|-------------|:--------:|
| `compartment_id`        | OCID of the compartment (tenancy) in which to create the budget.   | `string`            | n/a         |   yes    |
| `display_name`          | Human-readable name for the budget.                               | `string`            | n/a         |   yes    |
| `description`           | Description of the budget.                                         | `string`            | `null`      |    no    |
| `target_compartment_id` | OCID of the compartment the budget tracks spend for.              | `string`            | n/a         |   yes    |
| `amount`                | Budget amount in the tenancy currency. Must be a whole number.    | `number`            | n/a         |   yes    |
| `reset_period`          | How often the budget resets.                                      | `string`            | `"MONTHLY"` |    no    |
| `alert_rules`           | Alert rules notifying recipients on threshold crossings. See [Alert rules](#alert-rules). | `list(object(...))` | `[]`        |    no    |
| `freeform_tags`         | Free-form tags applied to the budget.                             | `map(string)`       | `{}`        |    no    |
| `defined_tags`          | Defined tags applied to the budget, keyed `namespace.key`.        | `map(string)`       | `{}`        |    no    |

## Outputs

| Name             | Description                                     |
|------------------|-------------------------------------------------|
| `id`             | OCID of the budget.                             |
| `display_name`   | Display name of the budget.                     |
| `amount`         | Budget amount in the tenancy currency.          |
| `alert_rule_ids` | OCIDs of the alert rules attached to the budget.|
| `state`          | Lifecycle state of the budget.                  |

## Testing

```sh
terraform init -backend=false
terraform test
```

The suite in [`tests/`](tests) uses a mocked OCI provider, so it needs no credentials
and no cloud resources. `mock_provider` requires Terraform (or OpenTofu) >= 1.7; the
module itself still supports >= 1.5.

## License

[MIT](LICENSE)
