# Architecture Decision Records (ADRs)

This directory captures the **why** behind the structural choices in this
repo. Each ADR is short, dated, and immutable once accepted — supersede
rather than edit.

Format loosely follows [Michael Nygard's template](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions).

## Index

| # | Status | Title |
|---|---|---|
| [0001](0001-policy-driven-network-group-membership.md) | Accepted | Policy-driven Network Group membership |
| [0002](0002-parent-child-avnm-topology.md) | Accepted | Parent + child AVNM topology |
| [0003](0003-per-hub-management-group-scope.md) | Accepted | Per-hub management group as AVNM scope |
| [0004](0004-terraform-azapi-vs-azurerm.md) | Accepted | Use `azapi` for AVNM resources in Terraform |
| [0005](0005-three-parallel-iac-implementations.md) | Accepted | Maintain Bicep, Terraform, and ARM in parallel |
| [0006](0006-baseline-security-admin-rules-at-parent.md) | Accepted | Baseline SecurityAdmin rules live at the parent AVNM |
| [0007](0007-no-automated-avnm-commit.md) | Accepted | IaC does not auto-commit AVNM configurations |

## How to add a new ADR

1. Copy `_template.md` to `NNNN-short-kebab-title.md` (next free number).
2. Fill in Context / Decision / Consequences / Alternatives.
3. Set Status to `Proposed` in the PR; flip to `Accepted` when merged.
4. Add a row to the index above.
5. If it supersedes an older ADR, set the older one's Status to
   `Superseded by NNNN` and link forward.
