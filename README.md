# Ascend Scaffolding

Infrastructure-as-Code scaffolding for an Azure Virtual Network Manager (AVNM)
hub-and-spoke SaaS POC, grounded in Azure Policy.

## Layout (planned)

```
policy/      Azure Policy definitions, initiative, and assignments (foundation)
bicep/       Bicep implementation (primary)
terraform/   Terraform implementation (parallel)
arm/         ARM JSON implementation (parallel)
```

## Architecture summary

- **Parent AVNM** at the root management group (`mg-saas-platform`) for
  cross-region governance and baseline SecurityAdmin rules.
- **Three child AVNM instances**, one per region (East US, West US 2, Central US),
  each acting as a transit hub for up to `maxSpokesPerHub` spokes (default 500).
- **Azure Policy** drives dynamic Network Group membership via the
  `addToNetworkGroup` effect, keyed off a VNet tag (`avnmGroup`).
- Parameterized to scale from a 500-spoke POC to 10,000+ spokes across multiple
  regions and DR pairs.

## Status

- [x] Repository scaffolded
- [ ] Policy foundation (in progress — see PR #1)
- [ ] Bicep modules
- [ ] Terraform modules
- [ ] ARM templates

## CI

- [IaC Validate workflow](.github/workflows/iac-validate.yml)
