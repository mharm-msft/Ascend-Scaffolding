# 0001. Policy-driven Network Group membership

- **Status:** Accepted
- **Date:** 2026-05-21
- **Deciders:** Platform networking, Cloud governance

## Context

AVNM Network Groups can be populated two ways:

1. **Static membership** — explicit `staticMember` resources, one per VNet.
2. **Dynamic membership** — Azure Policy with the `addToNetworkGroup`
   effect (`Microsoft.Network.Data` mode), keyed off a property such as
   a tag.

We expect the POC to start at ≈500 spokes per hub and grow to 10,000+
across regions and DR pairs. Spokes will be created by many different
landing-zone subscription owners on their own cadence — the platform team
is not in the critical path for every spoke deployment.

## Decision

All spoke membership is **policy-driven**, keyed on the tag `avnmGroup`.
The IaC creates Network Groups but does **not** create static members.

The tag value maps 1:1 to a Network Group name on a specific child AVNM,
e.g. `avnmGroup=east-prod-spokes` maps to NG `prod-spokes` on `avnm-hub-east`.

## Consequences

- **Positive:**
  - Onboarding a spoke is a single tag operation — no IaC PR to the
    platform repo, no static-member sprawl.
  - Scales naturally to 10k+ spokes; AVNM evaluates membership server-side.
  - Tag changes (re-homing a spoke) propagate without IaC drift.
- **Negative / trade-offs:**
  - Membership is **only** as trustworthy as the tag governance.
    Mitigated by the `require-spoke-membership-tag`,
    `deny-hub-tag-on-spoke-pattern`, and `inherit-spoke-tag-from-rg`
    policies in `policy/definitions/`.
  - Existing tagged VNets created **before** policy assignment require a
    compliance scan (`az policy state trigger-scan`) to be enrolled.
  - Per-NG policy assignments must be deployed **after** the AVNM /
    Network Groups exist (we cannot reference a non-existent NG ID).
- **Follow-ups required:**
  - Document the deploy order in `policy/README.md` (done).
  - Add CI to verify the tag-value list in the root assignment matches
    the NG names declared in IaC (proposed in ADR 0005 / CI follow-up).

## Alternatives considered

- **Static membership generated from CMDB/inventory** — rejected because
  it puts the platform team on the critical path of every spoke and
  requires CMDB authority over tags we don't currently own.
- **Mixed (static for platform spokes, dynamic for app spokes)** —
  rejected for the POC to keep the model uniform. Re-evaluate if a
  shared-services spoke (e.g. AzFW, DNS) needs to be guaranteed in the
  group regardless of tag drift.
