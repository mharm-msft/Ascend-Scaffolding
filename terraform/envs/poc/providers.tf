terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.parent_subscription_id
  alias           = "parent"
}

# One aliased azurerm provider per hub subscription. Configured dynamically
# at the root module so child modules can pick the correct provider.
provider "azurerm" {
  features {}
  subscription_id = length(var.hubs) > 0 ? var.hubs[0].subscription_id : null
  alias           = "hub0"
}

provider "azurerm" {
  features {}
  subscription_id = length(var.hubs) > 1 ? var.hubs[1].subscription_id : null
  alias           = "hub1"
}

provider "azurerm" {
  features {}
  subscription_id = length(var.hubs) > 2 ? var.hubs[2].subscription_id : null
  alias           = "hub2"
}

provider "azapi" {
  subscription_id = var.parent_subscription_id
}
