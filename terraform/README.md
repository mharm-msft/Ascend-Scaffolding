# Terraform — AVNM SaaS Hub-and-Spoke

Parallel Terraform implementation of the same AVNM topology delivered in Bicep.
Mirrors the parameter contract from the design doc so the two stay diff-able.

## Prereqs

1. Management groups exist: `mg-saas-platform` (root) and `mg-hub-eastus`,
   `mg-hub-westus`, `mg-hub-centralus` (children).
2. Caller has `Network Contributor` + `Resource Policy Contributor` at the root MG.
3. The Azure Policy foundation (`policy/`) is deployed.
4. The `azapi` provider is used because the AzureRM provider does not yet
   surface every AVNM property (`networkManagerScopeAccesses`, SecurityAdmin
   rule collections, etc.). The `azurerm` provider is used where stable.

## Layout

```
terraform/
├── envs/
│   └── poc/                       Root config (use this for `terraform apply`)
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── providers.tf
│       └── terraform.tfvars.example
└── modules/
    ├── avnm-parent/               Parent AVNM + baseline NGs + SecurityAdmin
    ├── avnm-child-hub/            Regional AVNM + hub VNet + connectivity + NGs
    └── security-admin-rules/      Reusable baseline deny-from-internet rules
```

## Usage

```bash
cd terraform/envs/poc
cp terraform.tfvars.example terraform.tfvars   # fill in subscription IDs
terraform init
terraform plan -out tfplan
terraform apply tfplan
```

## Parameter contract

| Variable | Type | Default | Notes |
|---|---|---|---|
| `root_mg_name` | string | `mg-saas-platform` | Scope for parent AVNM |
| `parent_avnm_name` | string | `avnm-root` | Parent instance |
| `parent_subscription_id` | string | _required_ | Hosts the parent AVNM resource |
| `parent_resource_group` | string | `rg-avnm-parent` | RG for parent AVNM |
| `max_spokes_per_hub` | number | `500` | Soft cap |
| `baseline_network_groups` | list(string) | 4 entries | Parent NGs |
| `child_network_groups` | list(string) | 3 entries | Default child NGs |
| `hubs` | list(object) | 3 entries | See `variables.tf` |
| `tag_key_for_membership` | string | `avnmGroup` | Must match Policy |
| `enable_security_admin_baseline` | bool | `true` | Push deny rules from parent |

## Design notes

- Uses **for_each** keyed by hub name so per-hub state stays stable when hubs
  are added or reordered in `var.hubs`.
- Connectivity configuration uses **`hub_and_spoke`** topology with
  `delete_existing_peerings_enabled = true` to reconcile manual peerings.
- Network Groups are NOT pre-populated here — the Policy foundation
  (`add-vnet-to-networkgroup`) handles dynamic membership.
- AVNM `commit` (deployment to regions) is intentionally **not** automated
  here. Use `az network manager post-commit` or the portal after `apply`.

## What this does NOT do

- Does not create management groups (assumed pre-existing).
- Does not create spoke VNets (those belong to landing-zone subscriptions).
- Does not deploy/commit AVNM configurations.
- Does not assign the per-NG Policy mapping templates — see `policy/assignments`.
