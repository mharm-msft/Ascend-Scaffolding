# 0002. Parent + child AVNM topology

- **Status:** Accepted
- **Date:** 2026-05-21
- **Deciders:** Platform networking

## Context

A single AVNM instance can manage a large topology, but:

- It has a single SecurityAdmin enforcement boundary.
- Connectivity configurations are global per-AVNM — mixing regional
  hub-and-spoke topologies in one instance complicates per-region change
  windows.
- Blast radius of an AVNM commit covers everything in scope.

We need governance that applies *everywhere* (deny inbound RDP/SMB from
Internet) alongside regional connectivity that the regional networking
team can iterate on independently.

## Decision

Deploy **one parent AVNM at the root management group** (`mg-saas-platform`)
plus **one child AVNM per region** at the corresponding per-hub MG
(`mg-hub-eastus`, `mg-hub-westus`, `mg-hub-centralus`).

- Parent AVNM: cross-region governance, baseline SecurityAdmin rules,
  baseline Network Groups (`all-spokes`, `prod`, `nonprod`, `dr`).
- Child AVNM: regional hub VNet, regional Network Groups
  (`prod-spokes`, `nonprod-spokes`, `dr-spokes`), HubAndSpoke connectivity
  configuration.

## Consequences

- **Positive:**
  - Baseline security posture is owned in one place and inherited.
  - Per-region change windows are isolated — committing the East AVNM
    does not affect West.
  - Each child AVNM's spoke cap (`maxSpokes`, soft) is independent;
    scaling one region doesn't force a global rethink.
- **Negative / trade-offs:**
  - Two AVNM resources to operate per region (parent + child).
  - Cross-region spoke-to-spoke (when needed) requires `isGlobal=True` on
    the parent's connectivity configuration in a future iteration.
- **Follow-ups required:**
  - Decide global connectivity stance once the second region is live.
  - Region-specific SecurityAdmin rule collections (proposed PR).

## Alternatives considered

- **Single global AVNM** — rejected for blast radius and per-region
  iteration concerns.
- **One AVNM per region, no parent** — rejected because there is no
  natural place to own cross-region governance; we'd duplicate rules.
