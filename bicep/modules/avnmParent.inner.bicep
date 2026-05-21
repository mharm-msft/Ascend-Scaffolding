// Inner (resource group scoped) module for the parent AVNM — actually creates the resource.
targetScope = 'resourceGroup'

param name string
param location string
param rootMgName string
param baselineNetworkGroups array
param enableSecurityAdminBaseline bool

var rootMgId = tenantResourceId('Microsoft.Management/managementGroups', rootMgName)

resource avnm 'Microsoft.Network/networkManagers@2024-05-01' = {
  name: name
  location: location
  properties: {
    networkManagerScopes: {
      managementGroups: [
        rootMgId
      ]
      subscriptions: []
    }
    networkManagerScopeAccesses: [
      'Connectivity'
      'SecurityAdmin'
    ]
  }
}

resource ngs 'Microsoft.Network/networkManagers/networkGroups@2024-05-01' = [for ng in baselineNetworkGroups: {
  parent: avnm
  name: ng
  properties: {
    description: 'Baseline network group ${ng} at parent AVNM'
  }
}]

module baselineSecurityAdmin 'securityAdminRules.bicep' = if (enableSecurityAdminBaseline) {
  name: 'baseline-security-admin'
  params: {
    avnmName: avnm.name
    appliesToNetworkGroupIds: [for (ng, i) in baselineNetworkGroups: ngs[i].id]
    collectionName: 'baseline-deny-from-internet'
  }
}

output avnmId string = avnm.id
output networkGroupIds array = [for (ng, i) in baselineNetworkGroups: ngs[i].id]
