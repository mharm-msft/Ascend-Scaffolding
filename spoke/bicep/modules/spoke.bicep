@description('Azure region.')
param location string

param vnetName string
param addressSpace array
param avnmGroupTagKey string
param avnmGroupTagValue string
param extraTags object
param subnets array
param createBaselineNsg bool

var membershipTag = {
  '${avnmGroupTagKey}': avnmGroupTagValue
}
var mergedTags = union(membershipTag, extraTags)

resource baselineNsg 'Microsoft.Network/networkSecurityGroups@2024-01-01' = if (createBaselineNsg) {
  name:     '${vnetName}-baseline-nsg'
  location: location
  tags:     mergedTags
  properties: {
    securityRules: [
      {
        name: 'deny-inbound-internet-management'
        properties: {
          description:              'Belt-and-braces deny on top of AVNM SecurityAdmin baseline'
          priority:                 4096
          direction:                'Inbound'
          access:                   'Deny'
          protocol:                 'Tcp'
          sourceAddressPrefix:      'Internet'
          sourcePortRange:          '*'
          destinationAddressPrefix: '*'
          destinationPortRanges:    [ '22', '445', '3389', '5985', '5986' ]
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name:     vnetName
  location: location
  tags:     mergedTags
  properties: {
    addressSpace: {
      addressPrefixes: addressSpace
    }
    subnets: [for s in subnets: {
      name: s.name
      properties: {
        addressPrefix: s.prefix
        networkSecurityGroup: contains(s, 'nsgId') ? {
          id: s.nsgId
        } : (createBaselineNsg ? {
          id: baselineNsg.id
        } : null)
      }
    }]
  }
}

output vnetId string = vnet.id
output subnetIds array = [for (s, i) in subnets: vnet.properties.subnets[i].id]
