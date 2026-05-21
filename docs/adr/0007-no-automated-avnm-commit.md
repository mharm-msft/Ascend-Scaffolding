# 0007. IaC does not auto-commit AVNM configurations

- **Status:** Accepted
- **Date:** 2026-05-21
- **Deciders:** Platform networking, Change management

## Context

Deploying an AVNM Connectivity or SecurityAdmin configuration via IaC
does **not** apply it to VNets. A separate `deploy`/`post-commit`
operation (per region, per configuration) rolls the configuration out
and actually changes data-plane behavior.

This is intentional in AVNM — the configuration is staged, then
deployed. Combining the two in a single `terraform apply` / `bicep
deploy` would:

- Couple data-plane change windows to IaC change windows.
- Hide rollouts inside a long IaC run, making them hard to schedule and
  audit.
- Make rollback awkward (the IaC removes the configuration entirely
  rather than rolling back the deployment).

## Decision

The IaC in this repo **only creates / updates the AVNM configuration
resources**. It does **not** call `post-commit` or trigger AVNM
deployments. Rolling a configuration to a region is a separate,
explicit operation:

```bash
az network manager post-commit \
  --network-manager-name <avnm> \
  --resource-group <rg> \
  --target-locations <regions> \
  --configuration-ids <configIds> \
  --commit-type Connectivity
```

This is documented in each implementation's README.

## Consequences

- **Positive:**
  - IaC runs are idempotent and safe to re-run.
  - Rollouts happen on a human-approved schedule, with their own
    change ticket.
  - Rollback is `az network manager post-commit` against the previous
    configuration, not an IaC revert.
- **Negative / trade-offs:**
  - Two-step deployment increases procedural complexity for first-time
    operators.
  - Easy to forget to commit — mitigated by a CI check (follow-up) that
    diffs the latest configuration ID against the last deployed one.
- **Follow-ups required:**
  - Add an operator runbook (`docs/runbook-avnm-commit.md`) with the
    standard rollout / rollback procedure.
  - Optional: a thin GitHub Actions workflow `commit-avnm.yml` that
    runs `post-commit` on manual dispatch with explicit region
    selection.

## Alternatives considered

- **IaC auto-commits after deploy** — rejected for the reasons above
  (data plane coupling, rollback awkwardness).
- **Auto-commit only in non-prod** — rejected: divergence between
  non-prod and prod operational flows is a foot-gun; the muscle memory
  needs to be the same in both.
