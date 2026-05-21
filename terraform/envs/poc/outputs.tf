output "parent_avnm_id" {
  value       = module.avnm_parent.avnm_id
  description = "Resource ID of the parent AVNM."
}

output "child_avnm_ids" {
  value = compact([
    try(module.avnm_child_hub_0[0].avnm_id, ""),
    try(module.avnm_child_hub_1[0].avnm_id, ""),
    try(module.avnm_child_hub_2[0].avnm_id, ""),
  ])
  description = "Resource IDs of all child AVNM instances."
}

output "hub_vnet_ids" {
  value = compact([
    try(module.avnm_child_hub_0[0].hub_vnet_id, ""),
    try(module.avnm_child_hub_1[0].hub_vnet_id, ""),
    try(module.avnm_child_hub_2[0].hub_vnet_id, ""),
  ])
  description = "Resource IDs of the hub VNets, one per child hub."
}
