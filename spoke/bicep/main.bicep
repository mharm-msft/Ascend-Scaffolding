targetScope = 'subscription'

@description('Azure region.')
param location string

@description('Target resource group for the spoke.')
param resourceGroupName string

@description('Create the resource group (true) or assume it already exists (false).')
param createResourceGroup bool = true

@description('Name of the spoke VNet.')
param vnetName string

@description('CIDR(s) for the spoke VNet.')
param addressSpace array

@description('Tag key that drives AVNM Network Group membership. Must match the platform-wide setting.')
param avnmGroupTagKey string = 'avnmGroup'

@description('Tag value identifying which Network Group this spoke joins (e.g. east-prod-spokes).')
param avnmGroupTagValue string

@description('Additional tags merged on top of the AVNM membership tag.')
param extraTags object = {}

@description('Subnets to create. Each item: { name: string, prefix: string, nsgId?: string }.')
param subnets array = []

@description('Create a baseline NSG and attach it to every subnet that does not have a nsgId override.')
param createBaselineNsg bool = true

resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = if (createResourceGroup) {
  name:     resourceGroupName
  location: location
}

module spokeInner 'modules/spoke.bicep' = {
  name:  'spoke-${vnetName}'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    rg
  ]
  params: {
    location:           location
    vnetName:           vnetName
    addressSpace:       addressSpace
    avnmGroupTagKey:    avnmGroupTagKey
    avnmGroupTagValue:  avnmGroupTagValue
    extraTags:          extraTags
    subnets:            subnets
    createBaselineNsg:  createBaselineNsg
  }
}

output vnetId string = spokeInner.outputs.vnetId
output subnetIds array = spokeInner.outputs.subnetIds
