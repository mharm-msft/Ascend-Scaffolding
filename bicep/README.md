# Bicep — AVNM SaaS Hub-and-Spoke

Primary IaC implementation. Deploys the **parent AVNM** at the root management
group and **N child AVNM hubs** (default 3 — East / West / Central) at their
respective per-hub management groups.

## Prereqs

1. Management groups exist:
   - `mg-saas-platform` (root)
   - `mg-hub-eastus`, `mg-hub-westus`, `mg-hub-centralus` (children)
2. A landing-zone subscription is attached to each hub MG.
3. The Azure Policy foundation from `policy/` is deployed first.
4. Caller has `Network Contributor` + `Resource Policy Contributor` at the root MG.

## Layout

```
bicep/
├── main.bicep                       Orchestrator (targetScope = managementGroup)
├── main.bicepparam                  POC defaults (3 hubs, 500 spokes each)
└── modules/
    ├── avnmParent.bicep             Parent AVNM @ root MG + baseline NGs
    ├── avnmChildHub.bicep           Regional AVNM + hub VNet + connectivity
    └── securityAdminRules.bicep     Baseline deny-from-internet rules
```

## Parameter contract

| Parameter | Type | Default | Notes |
|---|---|---|---|
| `rootMgName` | string | `mg-saas-platform` | Scope for parent AVNM |
| `parentAvnmName` | string | `avnm-root` | Parent instance name |
| `parentSubscriptionId` | string | _required_ | Subscription that hosts parent AVNM resource |
| `parentResourceGroup` | string | `rg-avnm-parent` | RG for parent AVNM |
| `maxSpokesPerHub` | int | `500` | Soft cap; overridable per hub |
| `baselineNetworkGroups` | array | 4 entries | NGs at parent scope |
| `childNetworkGroups` | array | 3 entries | Default NGs at each child |
| `hubs` | array(object) | 3 entries | `{ name, location, mgName, subscriptionId, resourceGroup, addressSpace, maxSpokes?, networkGroups? }` |
| `tagKeyForMembership` | string | `avnmGroup` | Must match Policy assignment |
| `enableSecurityAdminBaseline` | bool | `true` | Push deny rules from parent |

## Deploy

```bash
LOCATION=eastus
ROOT_MG=mg-saas-platform

az deployment mg create \
  --management-group-id "$ROOT_MG" \
  --location "$LOCATION" \
  --template-file bicep/main.bicep \
  --parameters bicep/main.bicepparam \
  --parameters parentSubscriptionId=<your-sub-id>
```

For a single hub override (e.g. allow 1500 spokes in East), edit `main.bicepparam`:

```bicep
param hubs = [
  { name: 'avnm-hub-east', location: 'eastus', mgName: 'mg-hub-eastus'
  , subscriptionId: '<sub>', resourceGroup: 'rg-avnm-east'
  , addressSpace: '10.10.0.0/12', maxSpokes: 1500 }
  // ... others
]
```

## What this PR does NOT do (yet)

- Does **not** create management groups (assumed pre-existing).
- Does **not** create or tag spoke VNets — those land via the Policy foundation
  once they're created in spoke subscriptions.
- Does **not** auto-commit the AVNM Connectivity configuration. After deploy,
  run `az network manager deploy-status` and `az network manager post-commit`
  (or use the portal Deployments blade) to roll out to regions.
- Does **not** include SecurityAdmin rule collections beyond a single baseline
  collection. Region-specific or app-specific collections come in a follow-up PR.
