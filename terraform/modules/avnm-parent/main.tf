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

# Use azapi to create the AVNM resource so we can set networkManagerScopeAccesses cleanly.
resource "azapi_resource" "avnm" {
  type      = "Microsoft.Network/networkManagers@2024-05-01"
  name      = var.name
  location  = var.location
  parent_id = azurerm_resource_group.this.id

  body = {
    properties = {
      networkManagerScopes = {
        managementGroups = [var.root_mg_id]
        subscriptions    = []
      }
      networkManagerScopeAccesses = [
        "Connectivity",
        "SecurityAdmin"
      ]
    }
  }

  response_export_values = ["id"]
}

resource "azapi_resource" "network_groups" {
  for_each  = toset(var.baseline_network_groups)
  type      = "Microsoft.Network/networkManagers/networkGroups@2024-05-01"
  name      = each.value
  parent_id = azapi_resource.avnm.id

  body = {
    properties = {
      description = "Baseline network group ${each.value} at parent AVNM"
    }
  }

  response_export_values = ["id"]
}

module "security_admin_baseline" {
  count  = var.enable_security_admin_baseline ? 1 : 0
  source = "../security-admin-rules"

  providers = {
    azapi = azapi
  }

  avnm_id                       = azapi_resource.avnm.id
  applies_to_network_group_ids  = [for ng in azapi_resource.network_groups : ng.id]
  collection_name               = "baseline-deny-from-internet"
}
