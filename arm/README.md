# ARM — AVNM SaaS Hub-and-Spoke

ARM JSON implementation parallel to the Bicep and Terraform versions. Same
parameter contract, same resource shape — useful when an environment is
ARM-only (e.g. constrained customer pipelines) or as the de-sugared output
you can review when reading the Bicep.

## Layout

```
arm/
├── azuredeploy.json                 Orchestrator (managementGroupDeploymentTemplate)
├── azuredeploy.parameters.json      POC parameters (3 hubs × 500 spokes)
└── nested/
    ├── avnmParent.json              Subscription-scope: parent AVNM + baseline NGs
    ├── avnmParentInner.json         RG-scope: actual AVNM resource
    ├── avnmChildHub.json            Subscription-scope: child AVNM + hub VNet
    ├── avnmChildHubInner.json       RG-scope: AVNM + VNet + connectivity
    └── securityAdminRules.json      RG-scope: baseline deny-from-internet rules
```

Nested templates are referenced **by relative path** (`relativePath`) in the
orchestrator. They must therefore be deployed either from a
Git-linked deployment artifact or from a Storage Account with a SAS token —
see `Deploy` below.

## Deploy (from a local clone, using --template-uri)

Upload `nested/` to a storage container, then:

```bash
ROOT_MG=mg-saas-platform
LOCATION=eastus

az deployment mg create \
  --management-group-id "$ROOT_MG" \
  --location "$LOCATION" \
  --template-file arm/azuredeploy.json \
  --parameters @arm/azuredeploy.parameters.json
```

When running from a local clone, the `relativePath` in nested deployments
is resolved relative to the orchestrator file. The Azure CLI handles this
transparently as of `az` 2.50+.

## Parameter contract

Identical to `bicep/main.bicep` and `terraform/envs/poc/variables.tf`:

| Parameter | Type | Notes |
|---|---|---|
| `rootMgName` | string | Scope for parent AVNM |
| `parentAvnmName` | string | Parent AVNM resource name |
| `parentSubscriptionId` | string | Subscription hosting parent AVNM resource |
| `parentResourceGroup` | string | RG for parent AVNM |
| `parentLocation` | string | Region for parent AVNM control plane |
| `maxSpokesPerHub` | int | Soft cap per hub |
| `baselineNetworkGroups` | array | Parent NGs |
| `childNetworkGroups` | array | Default child NGs |
| `hubs` | array(object) | One entry per region |
| `tagKeyForMembership` | string | Tag key for Policy NG add |
| `enableSecurityAdminBaseline` | bool | Push deny rules from parent |

## Notes

- ARM templates do **not** support `optional()` parameters. The orchestrator
  uses `if(contains(hubs[i], 'maxSpokes'), ..., maxSpokesPerHub)` so per-hub
  overrides still work.
- AVNM resource API version pinned to `2024-05-01`.
- The orchestrator deploys parent first, then loops over hubs with `copy`.
- For a 4th hub, just add another object to the `hubs` array — unlike Terraform,
  ARM/Bicep handle dynamic provider scope natively.
