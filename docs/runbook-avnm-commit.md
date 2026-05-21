# Runbook: Commit (deploy) an AVNM configuration

Closes ADR [0007](adr/0007-no-automated-avnm-commit.md): IaC stages the
configuration, **this runbook deploys it**. Two layers, two change
tickets, two muscle-memories.

## When to use

- After merging a PR that modifies any AVNM Connectivity or SecurityAdmin
  configuration (parent or child).
- After moving a spoke between Network Groups (re-tagging).
- During a planned rollback to a previous configuration revision.
- During DR exercises that re-home `*-dr-spokes`.

## Pre-flight

1. **Confirm the IaC change is merged and applied** in the target
   subscription. (`bicep deploy` / `terraform apply` / `az deployment mg
   create` must have completed.)
2. **Identify the AVNM** and **configuration IDs** to deploy:

   ```bash
   AVNM_RG=rg-avnm-east
   AVNM_NAME=avnm-hub-east
   SUB=<hub-subscription-id>

   az account set --subscription "$SUB"

   # List connectivity configurations
   az network manager connect-config list \
     --network-manager-name "$AVNM_NAME" \
     --resource-group "$AVNM_RG" \
     -o table

   # List security admin configurations
   az network manager security-admin-config list \
     --network-manager-name "$AVNM_NAME" \
     --resource-group "$AVNM_RG" \
     -o table
   ```

3. **Capture the current (pre-change) deployment status** — you'll need
   it for rollback:

   ```bash
   az network manager list-deploy-status \
     --network-manager-name "$AVNM_NAME" \
     --resource-group "$AVNM_RG" \
     --regions eastus \
     --deployment-types Connectivity SecurityAdmin \
     -o json > /tmp/pre-deploy-status-$AVNM_NAME.json
   ```

4. **Announce the change window** in the platform-networking channel
   with the target AVNM, regions, and config IDs.

## Deploy

### Option A — Azure CLI (canonical)

```bash
AVNM_RG=rg-avnm-east
AVNM_NAME=avnm-hub-east
REGION=eastus

# Connectivity rollout
CONFIG_ID=$(az network manager connect-config show \
  --network-manager-name "$AVNM_NAME" \
  --resource-group "$AVNM_RG" \
  --name avnm-hub-east-hns \
  --query id -o tsv)

az network manager post-commit \
  --network-manager-name "$AVNM_NAME" \
  --resource-group "$AVNM_RG" \
  --commit-type Connectivity \
  --target-locations "$REGION" \
  --configuration-ids "$CONFIG_ID"

# SecurityAdmin rollout (parent or child)
SEC_ID=$(az network manager security-admin-config show \
  --network-manager-name "$AVNM_NAME" \
  --resource-group "$AVNM_RG" \
  --name baseline-security-admin \
  --query id -o tsv)

az network manager post-commit \
  --network-manager-name "$AVNM_NAME" \
  --resource-group "$AVNM_RG" \
  --commit-type SecurityAdmin \
  --target-locations "$REGION" \
  --configuration-ids "$SEC_ID"
```

### Option B — GitHub Actions (manual dispatch)

For the operator who doesn't want to grant themselves direct Azure CLI
access (or wants an auditable record).

> **Note:** the workflow file (`.github/workflows/commit-avnm.yml`) must
> be added by a maintainer with the `workflow` token scope — it cannot be
> created by the chat-tool token that pushed this runbook. The exact
> file content is provided alongside the PR that introduced this runbook.

1. Go to **Actions → “AVNM: commit configuration” → Run workflow**.
2. Fill in:
   - `avnm_resource_id` — full ARM ID of the AVNM.
   - `commit_type` — `Connectivity` or `SecurityAdmin`.
   - `target_locations` — comma-separated regions (e.g. `eastus,westus2`).
   - `configuration_ids` — comma-separated config IDs.
   - `dry_run` — `true` to print and exit without calling Azure.
3. The job posts the commit and prints the resulting deployment-status
   payload.

The workflow uses OIDC federation; the calling identity must have
`Microsoft.Network/networkManagers/commit/action` on the AVNM.

## Verify

1. Poll deployment status until `deploymentStatus == "Deployed"`:

   ```bash
   watch -n 5 "az network manager list-deploy-status \
     --network-manager-name $AVNM_NAME \
     --resource-group $AVNM_RG \
     --regions $REGION \
     --deployment-types Connectivity SecurityAdmin \
     -o table"
   ```

   Typical p50: 2–5 minutes for connectivity, 1–3 for security admin.
   p95: 10 minutes. Open a support ticket beyond 30 minutes in one region.

2. Spot-check membership and effective rules on a sample spoke:

   ```bash
   SPOKE_VNET_ID=<spoke-vnet-resource-id>

   az network manager list-effective-vnet \
     --network-manager-name "$AVNM_NAME" \
     --resource-group "$AVNM_RG" \
     --query "value[?id=='$SPOKE_VNET_ID']"

   az network vnet show --ids "$SPOKE_VNET_ID" \
     --query "properties.virtualNetworkPeerings[].{name:name,state:peeringState,remote:remoteVirtualNetwork.id}" -o table
   ```

3. For SecurityAdmin: confirm a representative NIC's effective rules
   include the expected `NetworkManager` block:

   ```bash
   NIC_ID=<nic-resource-id-in-spoke>
   az network nic list-effective-nsg --ids "$NIC_ID" \
     -o json | jq '.value[].effectiveSecurityRules[] | select(.name | contains("deny-inbound"))'
   ```

4. Tick off the change ticket with: deployment timestamp, regions, config
   IDs, verification evidence (link to a workflow run if Option B).

## Rollback

Rollback is **not** an IaC revert. It is committing the **previously
deployed** configuration revision against the same regions.

1. Inspect the pre-change snapshot you saved in step 3 of Pre-flight and
   extract `configurationIds` from the previous deployment.
2. Re-run `az network manager post-commit` with those IDs.
3. If the previous configuration revision was deleted (rare), the next
   best option is:
   - Revert the IaC PR.
   - Re-apply IaC.
   - Re-commit the new (restored) configuration IDs.

   This is slower; prefer not deleting configuration resources during a
   change window.

## Common failure modes

| Symptom | Likely cause | Action |
|---|---|---|
| `post-commit` returns 403 | RBAC missing `commit/action` on AVNM | Grant `Network Contributor` at the AVNM (or `commit/action` only via custom role). |
| Status stuck `Deploying` >30 min in one region | Region-side AVNM throttling | Open a Microsoft support case with the deployment ID. |
| Spoke not in expected peering | Tag wrong, or Policy compliance not yet evaluated | Trigger scan: `az policy state trigger-scan --resource-group <spoke-rg>`. |
| SecurityAdmin rule not effective on NIC | NIC is in a subnet that AVNM doesn't manage (delegated subnet, etc.) | See AVNM docs on subnet exclusions; mitigate with NSG. |
| `deleteExistingPeering` removed a peering you wanted to keep | A hand-built peering pre-existed and was reconciled away | Either re-create the peering as IaC (preferred) or remove the spoke from the NG so AVNM stops managing it. |

## Related

- ADR [0007](adr/0007-no-automated-avnm-commit.md) — IaC does not
  auto-commit AVNM configurations.
- ADR [0006](adr/0006-baseline-security-admin-rules-at-parent.md) —
  Baseline SecurityAdmin rules live at the parent AVNM.
