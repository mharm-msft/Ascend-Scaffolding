output "avnm_id" {
  value       = azapi_resource.avnm.id
  description = "Resource ID of the parent AVNM."
}

output "network_group_ids" {
  value       = { for k, ng in azapi_resource.network_groups : k => ng.id }
  description = "Map of NG name -> resource ID."
}
