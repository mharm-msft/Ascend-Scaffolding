locals {
  root_mg_id = "/providers/Microsoft.Management/managementGroups/${var.root_mg_name}"

  # Normalize hubs: backfill max_spokes / network_groups from top-level defaults.
  hubs_normalized = [
    for h in var.hubs : merge(h, {
      max_spokes     = coalesce(h.max_spokes, var.max_spokes_per_hub)
      network_groups = coalesce(h.network_groups, var.child_network_groups)
    })
  ]

  hubs_by_name = { for h in local.hubs_normalized : h.name => h }
}

# ---------------------------------------------------------------------------
# Parent AVNM (root MG scope)
# ---------------------------------------------------------------------------
module "avnm_parent" {
  source = "../../modules/avnm-parent"

  providers = {
    azurerm = azurerm.parent
    azapi   = azapi
  }

  name                            = var.parent_avnm_name
  location                        = var.parent_location
  resource_group_name             = var.parent_resource_group
  root_mg_id                      = local.root_mg_id
  baseline_network_groups         = var.baseline_network_groups
  enable_security_admin_baseline  = var.enable_security_admin_baseline
}

# ---------------------------------------------------------------------------
# Child AVNM hubs (per-hub MG scope, per-hub subscription)
# ---------------------------------------------------------------------------
# Note: Terraform requires statically-configured providers per module. We use
# three aliased providers (hub0/hub1/hub2) and call the child module once per
# hub. To add a 4th hub, add a `hubN` provider in providers.tf and a new block.
module "avnm_child_hub_0" {
  count  = length(local.hubs_normalized) > 0 ? 1 : 0
  source = "../../modules/avnm-child-hub"

  providers = {
    azurerm = azurerm.hub0
    azapi   = azapi
  }

  name                = local.hubs_normalized[0].name
  location            = local.hubs_normalized[0].location
  resource_group_name = local.hubs_normalized[0].resource_group
  mg_id               = "/providers/Microsoft.Management/managementGroups/${local.hubs_normalized[0].mg_name}"
  address_space       = local.hubs_normalized[0].address_space
  max_spokes          = local.hubs_normalized[0].max_spokes
  network_groups      = local.hubs_normalized[0].network_groups
  tag_key             = var.tag_key_for_membership
}

module "avnm_child_hub_1" {
  count  = length(local.hubs_normalized) > 1 ? 1 : 0
  source = "../../modules/avnm-child-hub"

  providers = {
    azurerm = azurerm.hub1
    azapi   = azapi
  }

  name                = local.hubs_normalized[1].name
  location            = local.hubs_normalized[1].location
  resource_group_name = local.hubs_normalized[1].resource_group
  mg_id               = "/providers/Microsoft.Management/managementGroups/${local.hubs_normalized[1].mg_name}"
  address_space       = local.hubs_normalized[1].address_space
  max_spokes          = local.hubs_normalized[1].max_spokes
  network_groups      = local.hubs_normalized[1].network_groups
  tag_key             = var.tag_key_for_membership
}

module "avnm_child_hub_2" {
  count  = length(local.hubs_normalized) > 2 ? 1 : 0
  source = "../../modules/avnm-child-hub"

  providers = {
    azurerm = azurerm.hub2
    azapi   = azapi
  }

  name                = local.hubs_normalized[2].name
  location            = local.hubs_normalized[2].location
  resource_group_name = local.hubs_normalized[2].resource_group
  mg_id               = "/providers/Microsoft.Management/managementGroups/${local.hubs_normalized[2].mg_name}"
  address_space       = local.hubs_normalized[2].address_space
  max_spokes          = local.hubs_normalized[2].max_spokes
  network_groups      = local.hubs_normalized[2].network_groups
  tag_key             = var.tag_key_for_membership
}
