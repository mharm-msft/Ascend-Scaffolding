terraform {
  required_providers {
    azurerm = { source = "hashicorp/azurerm", configuration_aliases = [azurerm] }
    azapi   = { source = "Azure/azapi",       configuration_aliases = [azapi] }
  }
}

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
}

resource "azapi_resource" "avnm" {
  type      = "Microsoft.Network/networkManagers@2024-05-01"
  name      = var.name
  location  = var.location
  parent_id = azurerm_resource_group.this.id

  body = {
    properties = {
      networkManagerScopes = {
        managementGroups = [var.mg_id]
        subscriptions    = []
      }
      networkManagerScopeAccesses = [
        "Connectivity",
        "SecurityAdmin"
      ]
    }
    tags = {
      role      = "avnm-child-hub"
      maxSpokes = tostring(var.max_spokes)
      tagKey    = var.tag_key
    }
  }

  response_export_values = ["id"]
}

resource "azurerm_virtual_network" "hub" {
  name                = "${var.name}-hub-vnet"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = [var.address_space]

  tags = {
    role = "hub"
    avnm = var.name
  }
}

resource "azapi_resource" "network_groups" {
  for_each  = toset(var.network_groups)
  type      = "Microsoft.Network/networkManagers/networkGroups@2024-05-01"
  name      = each.value
  parent_id = azapi_resource.avnm.id

  body = {
    properties = {
      description = "Spoke network group ${each.value} for hub ${var.name}"
    }
  }

  response_export_values = ["id"]
}

resource "azapi_resource" "hub_and_spoke" {
  type      = "Microsoft.Network/networkManagers/connectivityConfigurations@2024-05-01"
  name      = "${var.name}-hns"
  parent_id = azapi_resource.avnm.id

  body = {
    properties = {
      description           = "Hub-and-Spoke topology for ${var.name} (max ${var.max_spokes} spokes)"
      connectivityTopology  = "HubAndSpoke"
      hubs = [
        {
          resourceId   = azurerm_virtual_network.hub.id
          resourceType = "Microsoft.Network/virtualNetworks"
        }
      ]
      isGlobal              = "False"
      deleteExistingPeering = "True"
      appliesToGroups = [
        for ng in azapi_resource.network_groups : {
          networkGroupId    = ng.id
          groupConnectivity = "None"
          useHubGateway     = "False"
          isGlobal          = "False"
        }
      ]
    }
  }
}
