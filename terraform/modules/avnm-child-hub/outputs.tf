output "avnm_id" {
  value       = azapi_resource.avnm.id
  description = "Resource ID of the child AVNM."
}

output "hub_vnet_id" {
  value       = azurerm_virtual_network.hub.id
  description = "Resource ID of the hub VNet."
}

output "network_group_ids" {
  value       = { for k, ng in azapi_resource.network_groups : k => ng.id }
  description = "Map of NG name -> resource ID."
}

output "connectivity_configuration_id" {
  value       = azapi_resource.hub_and_spoke.id
  description = "Resource ID of the HubAndSpoke connectivity configuration."
}
