# Spoke landing-zone modules

Self-contained spoke-VNet scaffolding for the AVNM hub-and-spoke topology
in this repo. A landing-zone owner deploys this **in their own
subscription**; nothing here touches the platform (hub) subscriptions.

## What it creates

- A resource group (optional — you can target an existing one).
- A VNet with the tag that drives AVNM Network Group membership
  (`avnmGroup = <value>`, default key configurable).
- One or more subnets.
- An optional baseline NSG attached to every subnet.

## What it does NOT create

- No peerings. AVNM connects the spoke to the regional hub once the
  policy-driven Network Group picks it up (see ADR
  [0001](../docs/adr/0001-policy-driven-network-group-membership.md)).
- No VPN/ExpressRoute gateways. Those live on the hub.
- No SecurityAdmin rules. Those are owned by the parent / child AVNM
  (ADR [0006](../docs/adr/0006-baseline-security-admin-rules-at-parent.md)).

## Membership flow (so you know what to expect after deploy)

1. `terraform apply` / `az deployment sub create` creates the VNet with the
   correct `avnmGroup` tag value.
2. Azure Policy (`addToNetworkGroup`) evaluates the new VNet and adds it
   to the corresponding Network Group on the regional child AVNM.
   First-time compliance can take up to 30 minutes; trigger early with:

   ```bash
   az policy state trigger-scan --resource-group <spoke-rg>
   ```

3. The platform team runs the [AVNM commit
   runbook](../docs/runbook-avnm-commit.md) (or scheduled automation) to
   roll the connectivity configuration. The spoke is then peered to the
   regional hub.
4. Baseline SecurityAdmin rules (deny inbound RDP/SSH/SMB/WinRM from
   Internet) apply automatically via NG inheritance.

## Picking the right tag value

The tag **key** is set by the platform team (default `avnmGroup`). The
tag **value** must match a Network Group name on the regional child AVNM:

| Region | Environment | Tag value | Network Group |
|---|---|---|---|
| East   | Prod    | `east-prod-spokes`    | `prod-spokes` on `avnm-hub-east` |
| East   | Nonprod | `east-nonprod-spokes` | `nonprod-spokes` on `avnm-hub-east` |
| East   | DR      | `east-dr-spokes`      | `dr-spokes` on `avnm-hub-east` |
| West   | Prod    | `west-prod-spokes`    | `prod-spokes` on `avnm-hub-west` |
| ...    | ...     | ...                   | ... |

The authoritative list is the `tagValueToNetworkGroup` map in the active
policy assignment — ask the platform team or check
`policy/assignments/perHub.bicep`.

## Bicep usage

```bicep
targetScope = 'subscription'

module spoke 'bicep/spoke.bicep' = {
  name: 'spoke-app42'
  params: {
    location:           'eastus'
    resourceGroupName:  'rg-app42-prod-eastus'
    vnetName:           'vnet-app42-prod-eastus'
    addressSpace:       ['10.100.42.0/24']
    avnmGroupTagValue:  'east-prod-spokes'
    subnets: [
      { name: 'app',  prefix: '10.100.42.0/26' }
      { name: 'data', prefix: '10.100.42.64/26' }
    ]
  }
}
```

Deploy:

```bash
az deployment sub create \
  --location eastus \
  --template-file bicep/main.bicep \
  --parameters @bicep/main.parameters.example.json
```

## Terraform usage

```hcl
module "spoke" {
  source = "./terraform/modules/spoke"

  location              = "eastus"
  resource_group_name   = "rg-app42-prod-eastus"
  create_resource_group = true
  vnet_name             = "vnet-app42-prod-eastus"
  address_space         = ["10.100.42.0/24"]
  avnm_group_tag_value  = "east-prod-spokes"

  subnets = [
    { name = "app",  prefix = "10.100.42.0/26" },
    { name = "data", prefix = "10.100.42.64/26" },
  ]
}
```

See `terraform/examples/app42-prod-eastus/` for a complete example.

## Parameter contract (Bicep ↔ Terraform)

| Bicep | Terraform | Notes |
|---|---|---|
| `location` | `location` | Azure region. |
| `resourceGroupName` | `resource_group_name` | Target RG. |
| `createResourceGroup` | `create_resource_group` | Default `true`. |
| `vnetName` | `vnet_name` | |
| `addressSpace` | `address_space` | `array` in Bicep, `list(string)` in TF. |
| `avnmGroupTagKey` | `avnm_group_tag_key` | Default `avnmGroup`. |
| `avnmGroupTagValue` | `avnm_group_tag_value` | Must match an NG name (see table above). |
| `subnets` | `subnets` | List of `{name, prefix}` (Bicep also accepts optional `nsgId`). |
| `createBaselineNsg` | `create_baseline_nsg` | Default `true`. |
| `extraTags` | `extra_tags` | Merged on top of `avnmGroup`. |
