targetScope = 'tenant'

@description('Name of the root management group for the SaaS platform.')
param rootMgName string = 'mg-saas-platform'

@description('Per-hub management group names to create under the root management group.')
param hubMgNames array = [
  'mg-hub-eastus'
  'mg-hub-westus'
  'mg-hub-centralus'
]

@description('Tenant root management group ID (usually the tenant ID).')
param tenantRootGroupId string = tenant().tenantId

resource rootManagementGroup 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: rootMgName
  properties: {
    details: {
      parent: {
        id: '/providers/Microsoft.Management/managementGroups/${tenantRootGroupId}'
      }
    }
  }
}

resource hubManagementGroups 'Microsoft.Management/managementGroups@2023-04-01' = [for hubMgName in hubMgNames: {
  name: hubMgName
  properties: {
    details: {
      parent: {
        id: rootManagementGroup.id
      }
    }
  }
}]

output rootMgId string = rootManagementGroup.id
output hubMgIds array = [for (hubMgName, i) in hubMgNames: hubManagementGroups[i].id]
