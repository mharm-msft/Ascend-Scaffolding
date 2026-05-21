// Inner (resource group scoped) module for a child AVNM hub.
targetScope = 'resourceGroup'

param name string
param location string
param mgName string
param addressSpace string
param maxSpokes int
param networkGroups array
param tagKey string

var mgId = tenantResourceId('Microsoft.Management/managementGroups', mgName)

resource avnm 'Microsoft.Network/networkManagers@2024-05-01' = {
  name: name
  location: location
  properties: {
    networkManagerScopes: {
      managementGroups: [
        mgId
      ]
      subscriptions: []
    }
    networkManagerScopeAccesses: [
      'Connectivity'
      'SecurityAdmin'
    ]
  }
  tags: {
    role: 'avnm-child-hub'
    maxSpokes: string(maxSpokes)
    tagKey: tagKey
  }
}

resource hubVnet 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: '${name}-hub-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressSpace
      ]
    }
  }
  tags: {
    role: 'hub'
    avnm: name
  }
}

resource ngs 'Microsoft.Network/networkManagers/networkGroups@2024-05-01' = [for ng in networkGroups: {
  parent: avnm
  name: ng
  properties: {
    description: 'Spoke network group ${ng} for hub ${name}'
  }
}]

// Hub-and-Spoke connectivity configuration. Applies to every NG on this child AVNM.
resource connectivity 'Microsoft.Network/networkManagers/connectivityConfigurations@2024-05-01' = {
  parent: avnm
  name: '${name}-hns'
  properties: {
    description: 'Hub-and-Spoke topology for ${name} (max ${maxSpokes} spokes)'
    connectivityTopology: 'HubAndSpoke'
    hubs: [
      {
        resourceId: hubVnet.id
        resourceType: 'Microsoft.Network/virtualNetworks'
      }
    ]
    isGlobal: 'False'
    deleteExistingPeering: 'True'
    appliesToGroups: [for (ng, i) in networkGroups: {
      networkGroupId: ngs[i].id
      groupConnectivity: 'None'
      useHubGateway: 'False'
      isGlobal: 'False'
    }]
  }
}

output avnmId string = avnm.id
output hubVnetId string = hubVnet.id
output networkGroupIds array = [for (ng, i) in networkGroups: ngs[i].id]
output connectivityConfigId string = connectivity.id
