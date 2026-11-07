# Changelog

All notable changes to this module are documented in this file. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the module follows
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.0] - 2026-11-07

### Added

- `target` input (`{ type = "COMPARTMENT" | "TAG", ids = [...] }`) for budgets on a
  cost-tracking tag (`namespace.key.value`) as well as on a compartment (#3).

### Changed

- `target_compartment_id` is now optional and stays as a shortcut for a compartment budget.
  Exactly one of `target_compartment_id` or `target` must be set; existing configurations
  that set `target_compartment_id` plan unchanged.

[Unreleased]: https://github.com/moveeeax/terraform-oci-budget/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/moveeeax/terraform-oci-budget/compare/v1.1.0...v1.2.0
