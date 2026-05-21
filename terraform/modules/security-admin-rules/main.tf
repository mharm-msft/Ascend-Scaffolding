terraform {
  required_providers {
    azapi = { source = "Azure/azapi", configuration_aliases = [azapi] }
  }
}

locals {
  deny_ports = [
    { name = "deny-inbound-rdp",    port = "3389" },
    { name = "deny-inbound-ssh",    port = "22"   },
    { name = "deny-inbound-smb",    port = "445"  },
    { name = "deny-inbound-winrm",  port = "5985" },
    { name = "deny-inbound-winrms", port = "5986" },
  ]
}

resource "azapi_resource" "security_admin_config" {
  type      = "Microsoft.Network/networkManagers/securityAdminConfigurations@2024-05-01"
  name      = "baseline-security-admin"
  parent_id = var.avnm_id

  body = {
    properties = {
      description = "Baseline SecurityAdmin configuration owned by the parent AVNM"
      applyOnNetworkIntentPolicyBasedServices = ["None"]
    }
  }
}

resource "azapi_resource" "rule_collection" {
  type      = "Microsoft.Network/networkManagers/securityAdminConfigurations/ruleCollections@2024-05-01"
  name      = var.collection_name
  parent_id = azapi_resource.security_admin_config.id

  body = {
    properties = {
      description = "Deny common management ports inbound from Internet"
      appliesToGroups = [
        for id in var.applies_to_network_group_ids : { networkGroupId = id }
      ]
    }
  }
}

resource "azapi_resource" "rules" {
  for_each  = { for idx, r in local.deny_ports : r.name => merge(r, { index = idx }) }
  type      = "Microsoft.Network/networkManagers/securityAdminConfigurations/ruleCollections/rules@2024-05-01"
  name      = each.value.name
  parent_id = azapi_resource.rule_collection.id

  body = {
    kind = "Custom"
    properties = {
      description           = "Deny ${each.value.name} from Internet"
      direction             = "Inbound"
      access                = "Deny"
      priority              = 100 + each.value.index
      protocol              = "Tcp"
      sources               = [{ addressPrefixType = "ServiceTag", addressPrefix = "Internet" }]
      destinations          = [{ addressPrefixType = "IPPrefix",   addressPrefix = "*" }]
      sourcePortRanges      = ["0-65535"]
      destinationPortRanges = [each.value.port]
    }
  }
}
