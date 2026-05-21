# Ascend Scaffolding

Infrastructure-as-Code scaffolding for an Azure Virtual Network Manager (AVNM)
hub-and-spoke SaaS POC, grounded in Azure Policy. Designed to scale from a
500-spoke POC to 10,000+ spokes across multiple regions and DR pairs.

## Architecture summary

- **Parent AVNM** at the root management group (`mg-saas-platform`) for
  cross-region governance and baseline SecurityAdmin rules.
- **Three child AVNM instances**, one per region (East US, West US 2, Central US),
  each acting as a transit hub for up to `maxSpokesPerHub` spokes (default 500).
- **Azure Policy** drives dynamic Network Group membership via the
  `addToNetworkGroup` effect (`Microsoft.Network.Data` mode), keyed off a
  VNet tag (`avnmGroup`).
- **Three parallel IaC implementations** — Bicep (primary), Terraform, and
  ARM — share an identical parameter contract so they stay diff-able. See
  [ADR 0005](docs/adr/0005-three-parallel-iac-implementations.md).

## Layout

```
bootstrap/   Tenant-scope management-group setup (one-time)
policy/      Azure Policy definitions, initiative, and per-hub assignments
bicep/       Bicep implementation (primary)
terraform/   Terraform implementation (uses azapi for AVNM resources)
arm/         ARM JSON implementation (de-sugared, for ARM-only pipelines)
spoke/       Spoke landing-zone modules (Bicep + Terraform)
docs/        Architecture Decision Records (ADRs) and operational runbooks
tools/       Repo-wide lint / consistency helpers
```

## Quick start

1. **Bootstrap** management groups (only on a fresh tenant) — see
   [`bootstrap/README.md`](bootstrap/README.md).
2. **Deploy the policy foundation** at the root MG — see
   [`policy/README.md`](policy/README.md). This must precede the IaC so
   Network Group membership and tag governance are live before VNets land.
3. **Deploy the AVNM topology** with your IaC of choice:
   - [`bicep/README.md`](bicep/README.md) (primary)
   - [`terraform/README.md`](terraform/README.md)
   - [`arm/README.md`](arm/README.md)
4. **Deploy per-hub NG-mapping policy assignments** (step 5 of the policy
   README) — these can only be assigned after the child AVNMs exist.
5. **Onboard spokes** from landing-zone subscriptions — see
   [`spoke/README.md`](spoke/README.md).
6. **Commit AVNM configurations** to regions — see the
   [AVNM commit runbook](docs/runbook-avnm-commit.md). IaC stages, the
   runbook deploys (ADR [0007](docs/adr/0007-no-automated-avnm-commit.md)).

## Status

- [x] Tenant bootstrap (`bootstrap/`)
- [x] Policy foundation (`policy/`)
- [x] Bicep implementation (`bicep/`)
- [x] Terraform implementation (`terraform/`)
- [x] ARM implementation (`arm/`)
- [x] Spoke landing-zone modules (`spoke/`)
- [x] Architecture Decision Records (`docs/adr/`)
- [x] AVNM commit runbook (`docs/runbook-avnm-commit.md`)
- [x] CI: IaC validation + tag-mapping consistency lint

## Design rationale

See [`docs/adr/`](docs/adr/) for the structural decisions behind this repo
(policy-driven membership, parent/child AVNM topology, per-hub MG scope,
`azapi` over `azurerm` for AVNM, parallel IaC stacks, baseline
SecurityAdmin at the parent, no automated AVNM commit).

## CI

- [`iac-validate`](.github/workflows/iac-validate.yml) — Bicep build,
  Terraform `fmt` + `validate`, ARM JSON parse + arm-ttk, and policy
  tag-value ↔ Network-Group-name consistency lint.
- [`commit-avnm`](.github/workflows/commit-avnm.yml) — manual-dispatch
  workflow to post-commit an AVNM configuration via OIDC.
