// Orchestrator: deploys parent AVNM @ root MG and N child AVNM hubs @ their per-hub MGs.
targetScope = 'managementGroup'

@description('Root management group name (deployment scope).')
param rootMgName string = 'mg-saas-platform'

@description('Parent AVNM resource name.')
param parentAvnmName string = 'avnm-root'

@description('Subscription that hosts the parent AVNM resource (the AVNM resource itself lives in a subscription, scope is set on it).')
param parentSubscriptionId string

@description('Resource group (in parentSubscriptionId) that hosts the parent AVNM resource.')
param parentResourceGroup string = 'rg-avnm-parent'

@description('Default per-hub spoke cap. Overridable per hub via hubs[].maxSpokes.')
@minValue(1)
@maxValue(10000)
param maxSpokesPerHub int = 500

@description('Network Groups created on the parent AVNM (baseline / cross-region categorisation).')
param baselineNetworkGroups array = [
  'all-spokes'
  'prod'
  'nonprod'
  'dr'
]

@description('Default Network Groups created on each child AVNM hub. Overridable per hub via hubs[].networkGroups.')
param childNetworkGroups array = [
  'prod-spokes'
  'nonprod-spokes'
  'dr-spokes'
]

@description('Child AVNM hub definitions — one per region.')
param hubs array = [
  {
    name: 'avnm-hub-east'
    location: 'eastus'
    mgName: 'mg-hub-eastus'
    subscriptionId: ''
    resourceGroup: 'rg-avnm-east'
    addressSpace: '10.10.0.0/12'
  }
  {
    name: 'avnm-hub-west'
    location: 'westus3'
    mgName: 'mg-hub-westus'
    subscriptionId: ''
    resourceGroup: 'rg-avnm-west'
    addressSpace: '10.30.0.0/12'
  }
  {
    name: 'avnm-hub-central'
    location: 'centralus'
    mgName: 'mg-hub-centralus'
    subscriptionId: ''
    resourceGroup: 'rg-avnm-central'
    addressSpace: '10.50.0.0/12'
  }
]

@description('Tag key used by Azure Policy to add VNets to Network Groups.')
param tagKeyForMembership string = 'avnmGroup'

@description('Whether to push baseline SecurityAdmin rules from the parent AVNM.')
param enableSecurityAdminBaseline bool = true

// -----------------------------------------------------------------------------
// Parent AVNM @ root MG
// -----------------------------------------------------------------------------
module parent 'modules/avnmParent.bicep' = {
  name: 'avnm-parent'
  scope: subscription(parentSubscriptionId)
  params: {
    name: parentAvnmName
    location: 'eastus'
    resourceGroupName: parentResourceGroup
    rootMgName: rootMgName
    baselineNetworkGroups: baselineNetworkGroups
    enableSecurityAdminBaseline: enableSecurityAdminBaseline
  }
}

// -----------------------------------------------------------------------------
// Child AVNM hubs (one deployment per hub MG)
// -----------------------------------------------------------------------------
module childHubs 'modules/avnmChildHub.bicep' = [for (hub, i) in hubs: {
  name: 'avnm-child-${hub.name}'
  scope: subscription(hub.subscriptionId)
  params: {
    name: hub.name
    location: hub.location
    resourceGroupName: hub.resourceGroup
    mgName: hub.mgName
    addressSpace: hub.addressSpace
    maxSpokes: contains(hub, 'maxSpokes') ? hub.maxSpokes : maxSpokesPerHub
    networkGroups: contains(hub, 'networkGroups') ? hub.networkGroups : childNetworkGroups
    tagKey: tagKeyForMembership
  }
}]

// -----------------------------------------------------------------------------
// Outputs
// -----------------------------------------------------------------------------
output parentAvnmId string = parent.outputs.avnmId
output childAvnmIds array = [for (hub, i) in hubs: childHubs[i].outputs.avnmId]
output childHubVnetIds array = [for (hub, i) in hubs: childHubs[i].outputs.hubVnetId]
