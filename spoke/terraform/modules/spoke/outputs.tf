output "vnet_id" {
  value       = azurerm_virtual_network.this.id
  description = "Resource ID of the spoke VNet."
}

output "subnet_ids" {
  value       = { for k, s in azurerm_subnet.this : k => s.id }
  description = "Map of subnet name -> resource ID."
}

output "baseline_nsg_id" {
  value       = length(azurerm_network_security_group.baseline) > 0 ? azurerm_network_security_group.baseline[0].id : null
  description = "Resource ID of the baseline NSG, or null if not created."
}

output "membership_tag" {
  value       = { (var.avnm_group_tag_key) = var.avnm_group_tag_value }
  description = "The tag k/v that drove AVNM Network Group membership for this spoke."
}
