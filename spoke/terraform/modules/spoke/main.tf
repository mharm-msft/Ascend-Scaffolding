terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

locals {
  membership_tag = {
    (var.avnm_group_tag_key) = var.avnm_group_tag_value
  }
  merged_tags = merge(local.membership_tag, var.extra_tags)
}

resource "azurerm_resource_group" "this" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
  tags     = local.merged_tags
}

resource "azurerm_network_security_group" "baseline" {
  count               = var.create_baseline_nsg ? 1 : 0
  name                = "${var.vnet_name}-baseline-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.merged_tags

  # TODO: split inline security_rule to azurerm_network_security_rule for v5 forward compat
  security_rule {
    name                       = "deny-inbound-internet-management"
    description                = "Belt-and-braces deny on top of AVNM SecurityAdmin baseline"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_address_prefix      = "Internet"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_ranges    = ["22", "445", "3389", "5985", "5986"]
  }

  depends_on = [azurerm_resource_group.this]
}

resource "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  tags                = local.merged_tags

  depends_on = [azurerm_resource_group.this]
}

resource "azurerm_subnet" "this" {
  for_each = { for s in var.subnets : s.name => s }

  name                 = each.value.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [each.value.prefix]
}

resource "azurerm_subnet_network_security_group_association" "baseline" {
  for_each = var.create_baseline_nsg ? { for s in var.subnets : s.name => s } : {}

  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = azurerm_network_security_group.baseline[0].id
}
