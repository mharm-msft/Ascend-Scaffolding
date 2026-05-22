# Scope: scaffolding vs. final product

This repo is **scaffolding**, not a finished SaaS platform. It provides the
governance + connectivity foundation (management groups, parent/child AVNM,
policy-driven Network Group membership, spoke landing-zone modules) on
which a customer-shaped SaaS is then built.

This document draws the line between **what scaffolding provides** and
**what is layered on top per customer** — so the foundation can stay
stable while vendors, cluster choices, and spoke workloads change.

## Principle

The scaffolding is **opinionated about shape, not about vendors**:

- Shape (fixed by scaffolding): tenant → root MG → per-hub MGs;
  parent AVNM for cross-region governance; one child AVNM per region as
  the transit hub; spokes joined to hubs via policy-driven Network Groups;
  spoke caps and regional fan-out sized for 10,000+ spokes.
- Vendor / product / workload (variable per customer): firewall NVA,
  load balancer, VPN/ExpressRoute choice, shared-services stack,
  telemetry stack, edge/API gateway, and what the spokes actually run
  (line-of-business apps, AI inference clusters, data planes, etc.).

The SaaS molds to the customer; the scaffolding does not.

## What scaffolding provides (stable)

| Layer | Provided by | Notes |
|---|---|---|
| Tenant + root/child MG hierarchy | `bootstrap/management-groups.bicep` | Per-hub MG scope is deliberate — see [ADR 0003](adr/0003-per-hub-management-group-scope.md). |
| Parent AVNM @ root MG | `bicep/modules/avnmParent.bicep` (+ Terraform/ARM equivalents) | Cross-region governance, baseline Network Groups, baseline SecurityAdmin rules ([ADR 0006](adr/0006-baseline-security-admin-rules-at-parent.md)). |
| Child AVNM per region (transit hub control plane) | `bicep/modules/avnmChildHub.bicep` (+ Terraform/ARM) | Regions in the default `hubs` array are examples only — override per deployment. |
| Policy-driven spoke membership | `policy/` (definitions, initiative, per-hub assignments) | `addToNetworkGroup` keyed off the `avnmGroup` VNet tag ([ADR 0001](adr/0001-policy-driven-network-group-membership.md)). |
| Spoke landing-zone module | `spoke/` (Bicep + Terraform) | VNet + subnets + tag; no peering, no gateways, no SecurityAdmin (those belong to the hub). |
| Three parallel IaC stacks | `bicep/`, `terraform/`, `arm/` | Identical parameter contract ([ADR 0005](adr/0005-three-parallel-iac-implementations.md)). |
| AVNM commit runbook | `docs/runbook-avnm-commit.md` | IaC does not auto-commit ([ADR 0007](adr/0007-no-automated-avnm-commit.md)). |

These are the pieces a downstream build should be able to rely on without
patching.

## What scaffolding deliberately does NOT provide (customer-shaped)

The items below are integration points, not omissions. Each one has a
clear seam in the scaffolding where a downstream build attaches.

### 1. Hub-VNet payload (firewall, LB, gateways)

Scaffolding creates the AVNM control plane and Network Groups; it does
not deploy the contents of the regional hub VNet. A downstream build
adds, per region, some combination of:

- **Firewall NVA** — Palo Alto, Fortinet, Check Point, Azure Firewall,
  or any other NGFW. Active/active vs. active/passive is a customer
  call. UDRs on spoke subnets force traffic through it.
- **Load balancer / ADC** — F5 BIG-IP, Citrix ADC, Azure Load Balancer,
  Application Gateway, NGINX, etc. Vendor and tier vary by customer.
- **VPN / ExpressRoute gateway** — for the "Administration" path and/or
  hybrid connectivity. Type (VPN vs. ER, SKU, BGP) is customer-driven.

> Seam: the hub VNet is owned by the platform team in the per-hub
> subscription declared in `hubs[].subscriptionId` /
> `hubs[].resourceGroup`. The child AVNM is already scoped to that hub,
> so a hub-VNet module just deploys alongside it.

### 2. Shared services

Scaffolding does not deploy shared services. A downstream build typically
adds a dedicated **shared-services spoke** that hosts things like:

- Private DNS zones / resolver
- Key Vault, container registry, artifact storage
- Self-hosted runners (GitHub Actions / Azure DevOps)
- Bastion, jumpboxes, PAM tooling
- Backup, secret rotation, certificate authorities

> Seam: add `shared-services` (or whatever name fits) to
> `childNetworkGroups`, add a matching entry to the per-hub policy
> assignment's `ngMappings`, and deploy the spoke via the existing
> `spoke/` module with the corresponding tag value.

### 3. Telemetry / security stack

Scaffolding does not provision Log Analytics, Sentinel, Defender plans,
or diagnostic settings. A downstream build typically adds:

- Regional Log Analytics workspaces
- Sentinel / SIEM forwarders
- Defender for Cloud plans at the MG scope
- Azure Policy DINE assignments for diagnostic settings on every
  resource type that matters

> Seam: per-hub MGs already exist (ADR 0003), so DINE assignments and
> workspace targeting can be scoped per region without reshaping the
> hierarchy. Drop new policy assignments alongside `policy/assignments/`.

### 4. Edge / API layer

Scaffolding does not deploy:

- **APIM** (per-region or multi-region) — lives in a spoke (or its own
  spoke per region) and is exposed through the hub.
- **Azure Front Door / global edge** — sits in front of regional APIM /
  app gateways. Entirely orthogonal to AVNM.
- **DNS** (public zones, traffic management) — customer-owned.

> Seam: APIM is just another spoke from the scaffolding's point of view
> (tag it into the appropriate NG). AFD is global and does not require
> changes to the hub-and-spoke layout.

### 5. Spoke workloads (incl. AI)

Scaffolding does not assume what runs in a spoke. Spokes may host:

- Traditional LOB apps (App Service, AKS, VMs)
- Data platforms (Synapse, Databricks, Fabric, Postgres/SQL clusters)
- **AI workloads** — Azure OpenAI / AI Foundry private endpoints,
  GPU-backed AKS inference clusters, vector stores, RAG pipelines,
  model-training subscriptions with their own quotas and regions
- Customer-tenant-isolated SaaS instances ("one customer per spoke" or
  "one customer per group of spokes")

The spoke module is intentionally minimal (VNet + subnets + tag) so
workload teams can layer arbitrary services on top without fighting the
landing zone. AI spokes in particular often need:

- Larger / non-overlapping address space (carve from a separate
  supernet — the scaffolding does not allocate IPAM)
- Private endpoints for Azure OpenAI / Storage / Key Vault — these
  resolve through the shared-services Private DNS resolver
- GPU SKUs that may force a specific region — the `hubs` array is
  region-flexible, so a workload's region constraint can drive which
  child AVNM it attaches to

> Seam: pick a tag value that maps to the right regional NG, deploy
> through the existing `spoke/` module, and add workload resources on
> top in the same subscription.

### 6. Multi-tenant / sovereignty

Scaffolding assumes a **single Entra tenant**. Customers requiring data
residency or tenant isolation (e.g. an EU tenant separate from a global
tenant) have two paths, both **out of scope for scaffolding**:

- Deploy this scaffolding independently in each tenant (two parallel
  roots, federated only at the workload layer).
- Stay single-tenant and use region-locked MGs + policy for residency.

> Seam: this is a topology decision, not a code change. It should be
> resolved before bootstrap, because changing root MG topology after
> spokes exist is expensive.

## What "the SaaS molds to the customer" means in practice

Two customers on the same scaffolding can look very different above the
seams:

| Concern | Customer A example | Customer B example |
|---|---|---|
| Regions | East US + West US 3 | Germany West Central + Sweden Central |
| Firewall | Palo Alto active/active | Azure Firewall Premium |
| LB / ADC | F5 BIG-IP VE | Application Gateway + WAF |
| Admin path | Site-to-site VPN | ExpressRoute + Bastion |
| Shared services | Self-hosted GH runners, Key Vault, Private DNS resolver | Azure DevOps agents, HSM-backed KV, third-party DNS |
| Telemetry | Sentinel + 3rd-party SIEM forwarder | Defender for Cloud only |
| Edge | APIM (Premium, internal VNet) + AFD | App Gateway only, no global edge |
| Spoke workloads | LOB SaaS apps, one tenant per spoke | AI inference clusters + RAG, shared per region |
| Tenancy | Single global tenant | Separate EU tenant |

The scaffolding underneath both is **identical**: same MG hierarchy
shape, same parent/child AVNM model, same policy-driven NG membership,
same spoke module. Vendors and clusters change above the line, not
below it.

## When scaffolding itself should change

Most "we picked a different vendor / region / workload" decisions
should **not** require scaffolding changes — they ride on the seams
above. Scaffolding changes are appropriate when the change is
structural, for example:

- The MG hierarchy shape changes (e.g. introducing per-environment MGs
  under each per-hub MG).
- The membership model changes (e.g. moving away from
  `addToNetworkGroup` to something else).
- A new IaC stack is added or removed (ADR 0005).
- Spoke caps need to move beyond AVNM's per-NG limits and require a
  re-shard.

Structural changes should be proposed via a new ADR in
[`docs/adr/`](adr/), not by editing accepted ADRs.
