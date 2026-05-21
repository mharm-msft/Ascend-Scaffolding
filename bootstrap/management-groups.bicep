targetScope = 'tenant'

@description('Root management group name.')
param rootMgName string = 'mg-saas-platform'

@description('Hub management group names.')
param hubMgNames array = [
  'mg-hub-eastus'
  'mg-hub-westus'
  'mg-hub-centralus'
]

resource rootMg 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: rootMgName
  properties: {
    displayName: rootMgName
  }
}

resource hubMgs 'Microsoft.Management/managementGroups@2023-04-01' = [for hubMgName in hubMgNames: {
  name: hubMgName
  properties: {
    displayName: hubMgName
    details: {
      parent: {
        id: rootMg.id
      }
    }
  }
}]

output rootMgId string = rootMg.id
output hubMgIds array = [for (hubMgName, i) in hubMgNames: hubMgs[i].id]
