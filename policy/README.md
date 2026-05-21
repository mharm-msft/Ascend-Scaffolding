# Azure Policy Foundation — AVNM SaaS Spoke Governance

This folder contains the **policy foundation** for the AVNM hub-and-spoke SaaS
POC. It must be deployed **before** the AVNM IaC (Bicep/Terraform/ARM) so that
Network Group dynamic membership and tag governance are in place when VNets
start landing.

## What's in here

```
policy/
├── definitions/
│   ├── require-spoke-membership-tag.json     Audit/Deny VNets missing the membership tag
│   ├── deny-hub-tag-on-spoke-pattern.json    Prevents hub-named VNets from being tagged as spokes
│   ├── add-vnet-to-networkgroup.json         Microsoft.Network.Data — addToNetworkGroup effect
│   └── inherit-spoke-tag-from-rg.json        Modify: inherit tag from parent RG
├── initiatives/
│   └── avnm-saas-spoke-governance.json       Bundles the three governance policies
├── assignments/
│   ├── root-mg-assignment.json               Initiative @ root MG (mg-saas-platform)
│   ├── hub-east-assignment.json              NG mapping assignments @ mg-hub-eastus
│   ├── hub-west-assignment.json              NG mapping assignments @ mg-hub-westus
│   └── hub-central-assignment.json           NG mapping assignments @ mg-hub-centralus
└── deploy.sh                                 Helper script (az CLI)
```

## Deploy order (critical)

| Step | What | Where |
|---|---|---|
| 1 | Deploy policy **definitions** + **initiative** | Root MG `mg-saas-platform` |
| 2 | Assign **initiative** (governance only) | Root MG |
| 3 | Deploy **Parent AVNM** (IaC, not in this folder) | Root MG / sub |
| 4 | Deploy **Child AVNMs + Network Groups** (IaC) | Each hub MG |
| 5 | Deploy **NG-mapping assignments** (`add-vnet-to-networkgroup`) | Each hub MG |
| 6 | Trigger **compliance scan** to backfill existing tagged VNets | `az policy state trigger-scan` |
| 7 | Commit AVNM Connectivity + SecurityAdmin configurations | Manual / pipeline |

`Microsoft.Network.Data` policies evaluate on VNet create / update / tag-change,
but step 6 is needed to add VNets that were tagged before the policy existed.

## Parameters you'll likely tune

| Parameter | Default | Notes |
|---|---|---|
| `tagKey` | `avnmGroup` | Tag policies and AVNM membership both key on this. |
| `tagRequirementEffect` | `Audit` | Flip to `Deny` once existing VNets are compliant. |
| `hubTagDenyEffect` | `Deny` | Hubs must never be tagged as spokes. |
| `hubNamePattern` | `*-hub-vnet` | Adjust if your hub naming differs. |
| `requireRegion` (per NG) | hub region | Pins membership to the hub region. Strongly recommended. |
| `allowedTagValues` | 9 NG values | Update when you add a new region / NG. |

## Identity notes

- `add-vnet-to-networkgroup` uses **`Microsoft.Network.Data`** mode and **does not**
  require a managed identity.
- `inherit-spoke-tag-from-rg` uses the **`modify`** effect and **does** require a
  managed identity with Contributor at the assignment scope — the root
  assignment template requests `SystemAssigned`.

## Next steps

After this PR merges:

1. Run `deploy.sh` (or the equivalent pipeline) against the root MG.
2. Proceed with the **Bicep modules** PR to deploy Parent + Child AVNMs.
3. Run the per-hub assignment templates with the real `subscriptionId` values.
