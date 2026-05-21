// Baseline SecurityAdmin rule collection — deny common management ports from Internet.
// Applied at parent AVNM scope to every baseline network group.
targetScope = 'resourceGroup'

@description('Name of the AVNM resource (parent or child) to add the rule collection to.')
param avnmName string

@description('Resource IDs of Network Groups this rule collection applies to.')
param appliesToNetworkGroupIds array

@description('Name of the rule collection.')
param collectionName string = 'baseline-deny-from-internet'

resource avnm 'Microsoft.Network/networkManagers@2024-05-01' existing = {
  name: avnmName
}

resource securityAdminConfig 'Microsoft.Network/networkManagers/securityAdminConfigurations@2024-05-01' = {
  parent: avnm
  name: 'baseline-security-admin'
  properties: {
    description: 'Baseline SecurityAdmin configuration owned by the parent AVNM'
    applyOnNetworkIntentPolicyBasedServices: [
      'None'
    ]
  }
}

resource ruleCollection 'Microsoft.Network/networkManagers/securityAdminConfigurations/ruleCollections@2024-05-01' = {
  parent: securityAdminConfig
  name: collectionName
  properties: {
    description: 'Deny common management ports inbound from Internet'
    appliesToGroups: [for ngId in appliesToNetworkGroupIds: {
      networkGroupId: ngId
    }]
  }
}

var denyPorts = [
  { name: 'deny-inbound-rdp',    port: '3389' }
  { name: 'deny-inbound-ssh',    port: '22'   }
  { name: 'deny-inbound-smb',    port: '445'  }
  { name: 'deny-inbound-winrm',  port: '5985' }
  { name: 'deny-inbound-winrms', port: '5986' }
]

resource rules 'Microsoft.Network/networkManagers/securityAdminConfigurations/ruleCollections/rules@2024-05-01' = [for (r, i) in denyPorts: {
  parent: ruleCollection
  name: r.name
  kind: 'Custom'
  properties: {
    description: 'Deny ${r.name} from Internet'
    direction: 'Inbound'
    access: 'Deny'
    priority: 100 + i
    protocol: 'Tcp'
    sources: [
      {
        addressPrefixType: 'ServiceTag'
        addressPrefix: 'Internet'
      }
    ]
    destinations: [
      {
        addressPrefixType: 'IPPrefix'
        addressPrefix: '*'
      }
    ]
    sourcePortRanges: [
      '0-65535'
    ]
    destinationPortRanges: [
      r.port
    ]
  }
}]

output configId string = securityAdminConfig.id
output ruleCollectionId string = ruleCollection.id
