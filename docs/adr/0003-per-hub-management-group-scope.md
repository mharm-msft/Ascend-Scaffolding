# 0003. Per-hub management group as AVNM scope

- **Status:** Accepted
- **Date:** 2026-05-21
- **Deciders:** Platform networking, Cloud governance

## Context

An AVNM `networkManagerScope` can be a list of management groups and/or
subscriptions. Spokes are created in many landing-zone subscriptions that
the platform team does not directly control.

We need a scope that:

- Picks up new spoke subscriptions automatically as they're created.
- Does not require the platform team to update IaC every time a new
  landing zone is onboarded.
- Stays narrow enough that policy and AVNM evaluation are bounded.

## Decision

Each child AVNM's `networkManagerScopes.managementGroups` is set to a
single **per-hub management group** (e.g. `mg-hub-eastus`). Landing-zone
subscriptions are placed under the appropriate per-hub MG by the
subscription-vending process.

The parent AVNM is scoped to the **root** MG (`mg-saas-platform`).

## Consequences

- **Positive:**
  - New spoke subscriptions are picked up automatically via MG
    inheritance — no IaC change.
  - Per-region spokes are evaluated only by the region's AVNM.
  - Policy assignments stack cleanly: governance at root, NG-mapping at
    per-hub MGs.
- **Negative / trade-offs:**
  - Misplacement of a subscription under the wrong MG silently sends
    its spokes to the wrong AVNM. Mitigation: subscription-vending
    enforces MG placement; periodic audit query (follow-up).
  - Cross-region failover (DR) needs spokes to be reachable from a
    different region's hub — handled via the `*-dr-spokes` NGs which
    can be re-pointed without moving the subscription.
- **Follow-ups required:**
  - Audit query / workbook: list spoke subscriptions whose MG and tag
    region disagree.

## Alternatives considered

- **Subscription-list scope** — rejected because it requires IaC churn
  every onboarding.
- **Single root-MG scope for all child AVNMs** — rejected: every AVNM
  would evaluate every spoke, increasing evaluation cost and coupling
  regions.
