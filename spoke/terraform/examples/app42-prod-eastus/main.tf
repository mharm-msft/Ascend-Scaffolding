terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
  }
}

provider "azurerm" {
  features {}
  # Set ARM_SUBSCRIPTION_ID or `subscription_id = "..."` to target the
  # landing-zone subscription that owns app42-prod.
}

module "spoke" {
  source = "../../modules/spoke"

  location              = "eastus"
  resource_group_name   = "rg-app42-prod-eastus"
  create_resource_group = true
  vnet_name             = "vnet-app42-prod-eastus"
  address_space         = ["10.100.42.0/24"]
  avnm_group_tag_value  = "east-prod-spokes"

  subnets = [
    { name = "app",  prefix = "10.100.42.0/26" },
    { name = "data", prefix = "10.100.42.64/26" },
  ]

  extra_tags = {
    app        = "app42"
    env        = "prod"
    owner      = "team-app42"
    costCenter = "CC-12345"
  }
}

output "vnet_id"    { value = module.spoke.vnet_id }
output "subnet_ids" { value = module.spoke.subnet_ids }
