// Child AVNM hub scoped to a per-hub management group.
// Creates the AVNM control plane resource, a hub VNet, per-hub Network Groups,
// and a HubAndSpoke connectivity configuration. Spoke membership is driven by Policy.
targetScope = 'subscription'

@description('Child AVNM name (e.g. avnm-hub-east).')
param name string

@description('Azure region for the AVNM and hub VNet.')
param location string

@description('Resource group hosting AVNM + hub VNet.')
param resourceGroupName string

@description('Per-hub management group name (scope for AVNM).')
param mgName string

@description('CIDR for the hub VNet (sized for the regional hub).')
param addressSpace string

@description('Soft cap on the number of spokes for this hub. Used for sizing + alerting; AVNM itself does not enforce.')
@minValue(1)
@maxValue(10000)
param maxSpokes int = 500

@description('Network Groups created on this child AVNM (one per environment).')
param networkGroups array

@description('Tag key Azure Policy uses to add VNets to these NGs.')
param tagKey string = 'avnmGroup'

resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
}

module inner 'avnmChildHub.inner.bicep' = {
  name: 'avnm-child-${name}-inner'
  scope: rg
  params: {
    name: name
    location: location
    mgName: mgName
    addressSpace: addressSpace
    maxSpokes: maxSpokes
    networkGroups: networkGroups
    tagKey: tagKey
  }
}

output avnmId string = inner.outputs.avnmId
output hubVnetId string = inner.outputs.hubVnetId
output networkGroupIds array = inner.outputs.networkGroupIds
