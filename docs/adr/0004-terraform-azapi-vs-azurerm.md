# 0004. Use `azapi` for AVNM resources in Terraform

- **Status:** Accepted
- **Date:** 2026-05-21
- **Deciders:** Platform networking, IaC working group

## Context

The HashiCorp `azurerm` provider tracks AVNM but, at the time of writing,
does not surface every property we need:

- `networkManagerScopeAccesses` accepting both `Connectivity` and
  `SecurityAdmin` cleanly.
- SecurityAdmin rule collection + rule resources with the full property
  surface (kind, copy of `appliesToGroups`, etc.).
- Newer connectivity-configuration shape (`hubs[].resourceType`,
  `deleteExistingPeering`).

Mixing two providers is operationally undesirable but blocking on the
resource-typed provider would delay delivery.

## Decision

In the Terraform implementation:

- **AVNM resources** (network manager, network groups, connectivity
  configurations, security admin configs, rule collections, rules) use
  the `Azure/azapi` provider against API version `2024-05-01`.
- **Surrounding resources** (resource groups, hub VNets) use `azurerm`
  because the typed provider is stable and ergonomic there.

## Consequences

- **Positive:**
  - Full property coverage today without waiting on provider releases.
  - The `azapi` resource bodies look almost identical to the Bicep /
    ARM resource bodies — easier to keep the three implementations
    in sync (see ADR 0005).
- **Negative / trade-offs:**
  - No `terraform fmt` / `tflint` schema validation of resource bodies
    — typos surface at `apply` time.
  - Drift detection is less ergonomic for `azapi` resources.
  - When `azurerm` catches up, we will likely want to migrate the AVNM
    resources back; that migration requires `terraform state mv` or
    re-imports.
- **Follow-ups required:**
  - Re-evaluate every six months whether `azurerm` coverage is
    sufficient to migrate off `azapi`.
  - Pin both provider versions in `required_providers` (done).

## Alternatives considered

- **All-azurerm, accept missing properties** — rejected: we'd lose
  SecurityAdmin rule fidelity.
- **All-azapi** — rejected: needlessly noisy for RGs/VNets which are
  stable in `azurerm`.
- **Wait for azurerm parity** — rejected: blocks the POC indefinitely.
