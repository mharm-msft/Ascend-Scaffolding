# 0005. Maintain Bicep, Terraform, and ARM in parallel

- **Status:** Accepted
- **Date:** 2026-05-21
- **Deciders:** Platform networking, IaC working group

## Context

Customer/partner environments in scope for this scaffolding mix all three
flavors of Azure IaC:

- **Bicep** — preferred for Microsoft-native teams; cleanest authoring
  experience for AVNM today.
- **Terraform** — mandated by some customers' existing pipelines and
  multi-cloud strategy.
- **ARM JSON** — required by a small number of constrained pipelines
  that cannot run `bicep` or `terraform` binaries.

Delivering only one would force the other consumers to translate by hand,
introducing drift.

## Decision

Maintain **all three** implementations under `bicep/`, `terraform/`, and
`arm/`. They share a **single parameter contract** (variable names,
types, defaults, and structure of the `hubs` array) so that a parameter
file written for one is mechanically translatable to the others.

Bicep is the **reference implementation** — it is the source of truth
when the three diverge; Terraform and ARM are kept in sync against it.

## Consequences

- **Positive:**
  - Each consumer picks their preferred flavor without giving up
    functionality.
  - The trio acts as cross-validation — if a property looks wrong in
    one, the other two are an immediate sanity check.
- **Negative / trade-offs:**
  - 3× maintenance for every change to the AVNM resource shape.
  - Risk of drift between implementations.
- **Follow-ups required:**
  - CI workflow that runs `bicep build`, `terraform validate`, and
    `az deployment mg what-if` on PRs touching any of the three
    (proposed in a follow-up PR).
  - Optional: a diff script that compares declared resource property
    keys across the three and flags divergence.

## Alternatives considered

- **Bicep-only** — rejected: blocks Terraform-mandated customers.
- **Terraform-only with `azapi`** — rejected: same property fidelity
  question for ARM-only consumers, and Bicep is a strictly nicer
  authoring experience for the Microsoft-native team.
- **Generate Terraform/ARM from Bicep** — considered. `bicep build`
  produces ARM, but Terraform requires a hand-written translation
  layer. Re-evaluate when a generally available Bicep-to-Terraform
  generator exists.
