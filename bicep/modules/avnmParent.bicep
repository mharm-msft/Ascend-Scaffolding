// Parent AVNM scoped to the root management group.
// Creates the AVNM resource (in a subscription/RG) but with management-group scope access,
// plus baseline Network Groups and an optional SecurityAdmin rule collection.
targetScope = 'subscription'

@description('Parent AVNM name.')
param name string

@description('Region for the parent AVNM control plane resource.')
param location string = 'eastus'

@description('Resource group that hosts the parent AVNM resource.')
param resourceGroupName string

@description('Root management group name (used to build the scope path).')
param rootMgName string

@description('Network Groups created on the parent AVNM.')
param baselineNetworkGroups array

@description('Push baseline SecurityAdmin rule collection from parent.')
param enableSecurityAdminBaseline bool = true

resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
}

module parentInner 'avnmParent.inner.bicep' = {
  name: 'avnm-parent-inner'
  scope: rg
  params: {
    name: name
    location: location
    rootMgName: rootMgName
    baselineNetworkGroups: baselineNetworkGroups
    enableSecurityAdminBaseline: enableSecurityAdminBaseline
  }
}

output avnmId string = parentInner.outputs.avnmId
output networkGroupIds array = parentInner.outputs.networkGroupIds
