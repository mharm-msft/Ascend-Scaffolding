# 0006. Baseline SecurityAdmin rules live at the parent AVNM

- **Status:** Accepted
- **Date:** 2026-05-21
- **Deciders:** Platform networking, Security

## Context

AVNM SecurityAdmin rules override NSGs. They are powerful, easy to
misuse, and unwinding a bad rule requires a commit cycle. We need a
clear ownership model: which rules live where, and who can change them.

Both parent and child AVNMs have `SecurityAdmin` in their
`networkManagerScopeAccesses`, so either could theoretically own any
rule. Without a convention, every team will pick differently.

## Decision

- **Baseline, organization-wide deny rules** (inbound RDP/SSH/SMB/WinRM
  from `Internet`) are owned by the **parent AVNM** and applied to the
  baseline Network Groups (`all-spokes`, `prod`, `nonprod`, `dr`).
- **Regional or app-specific rules** (e.g. allow intra-prod mesh in East,
  deny cross-environment traffic) live on the **child AVNM** for that
  region and apply to that child's NGs.
- A spoke is therefore subject to:
  1. Parent baseline (always)
  2. Region-specific rules (always, via region's child AVNM)
  3. NSGs (where they don't conflict with SecurityAdmin)

## Consequences

- **Positive:**
  - Clear ownership: security team owns the parent rules; regional
    networking owns child rules.
  - A regional incident never requires touching baseline deny rules.
  - Baseline is uniformly enforced — no region can opt out by accident.
- **Negative / trade-offs:**
  - Two RBAC scopes to manage (root MG vs per-hub MG).
  - Rule precedence is implicit (lower numeric priority wins inside a
    collection; parent collection vs child collection ordering depends
    on commit history). Mitigation: priority ranges are reserved per
    layer in a follow-up.
- **Follow-ups required:**
  - Reserve priority bands: parent `100–999`, regional `1000–4999`,
    app-specific `5000+`. Document and lint in CI.
  - Add region-specific rule collections (proposed follow-up PR).

## Alternatives considered

- **All rules on the parent** — rejected: blocks regional autonomy and
  creates a global change-window bottleneck.
- **All rules on the children** — rejected: baseline duplication and
  drift between regions.
