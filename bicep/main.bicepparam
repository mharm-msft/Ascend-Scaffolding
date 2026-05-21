using './main.bicep'

param rootMgName            = 'mg-saas-platform'
param parentAvnmName        = 'avnm-root'
param parentSubscriptionId  = '00000000-0000-0000-0000-000000000000'
param parentResourceGroup   = 'rg-avnm-parent'
param maxSpokesPerHub       = 500
param tagKeyForMembership   = 'avnmGroup'
param enableSecurityAdminBaseline = true

param baselineNetworkGroups = [
  'all-spokes'
  'prod'
  'nonprod'
  'dr'
]

param childNetworkGroups = [
  'prod-spokes'
  'nonprod-spokes'
  'dr-spokes'
]

// Override maxSpokes per hub when you need to lift the cap above the default.
param hubs = [
  {
    name: 'avnm-hub-east'
    location: 'eastus'
    mgName: 'mg-hub-eastus'
    subscriptionId: '00000000-0000-0000-0000-000000000000'
    resourceGroup: 'rg-avnm-east'
    addressSpace: '10.10.0.0/12'
  }
  {
    name: 'avnm-hub-west'
    location: 'westus2'
    mgName: 'mg-hub-westus'
    subscriptionId: '00000000-0000-0000-0000-000000000000'
    resourceGroup: 'rg-avnm-west'
    addressSpace: '10.30.0.0/12'
  }
  {
    name: 'avnm-hub-central'
    location: 'centralus'
    mgName: 'mg-hub-centralus'
    subscriptionId: '00000000-0000-0000-0000-000000000000'
    resourceGroup: 'rg-avnm-central'
    addressSpace: '10.50.0.0/12'
  }
]
