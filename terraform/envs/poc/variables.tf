variable "root_mg_name" {
  description = "Root management group name; scope for parent AVNM."
  type        = string
  default     = "mg-saas-platform"
}

variable "parent_avnm_name" {
  description = "Parent AVNM resource name."
  type        = string
  default     = "avnm-root"
}

variable "parent_subscription_id" {
  description = "Subscription that hosts the parent AVNM resource."
  type        = string
}

variable "parent_resource_group" {
  description = "Resource group (in parent_subscription_id) hosting the parent AVNM."
  type        = string
  default     = "rg-avnm-parent"
}

variable "parent_location" {
  description = "Region for parent AVNM control plane resource."
  type        = string
  default     = "eastus"
}

variable "max_spokes_per_hub" {
  description = "Soft cap on spokes per child hub; overridable per hub via hubs[].max_spokes."
  type        = number
  default     = 500

  validation {
    condition     = var.max_spokes_per_hub >= 1 && var.max_spokes_per_hub <= 10000
    error_message = "max_spokes_per_hub must be between 1 and 10000."
  }
}

variable "baseline_network_groups" {
  description = "Network Groups created on the parent AVNM."
  type        = list(string)
  default     = ["all-spokes", "prod", "nonprod", "dr"]
}

variable "child_network_groups" {
  description = "Default Network Groups created on each child AVNM hub."
  type        = list(string)
  default     = ["prod-spokes", "nonprod-spokes", "dr-spokes"]
}

variable "hubs" {
  description = "Child AVNM hub definitions — one per region."
  type = list(object({
    name            = string
    location        = string
    mg_name         = string
    subscription_id = string
    resource_group  = string
    address_space   = string
    max_spokes      = optional(number)
    network_groups  = optional(list(string))
  }))

  default = [
    {
      name            = "avnm-hub-east"
      location        = "eastus"
      mg_name         = "mg-hub-eastus"
      subscription_id = ""
      resource_group  = "rg-avnm-east"
      address_space   = "10.10.0.0/12"
    },
    {
      name            = "avnm-hub-west"
      location        = "westus2"
      mg_name         = "mg-hub-westus"
      subscription_id = ""
      resource_group  = "rg-avnm-west"
      address_space   = "10.30.0.0/12"
    },
    {
      name            = "avnm-hub-central"
      location        = "centralus"
      mg_name         = "mg-hub-centralus"
      subscription_id = ""
      resource_group  = "rg-avnm-central"
      address_space   = "10.50.0.0/12"
    }
  ]
}

variable "tag_key_for_membership" {
  description = "Tag key used by Azure Policy to add VNets to Network Groups."
  type        = string
  default     = "avnmGroup"
}

variable "enable_security_admin_baseline" {
  description = "Push baseline SecurityAdmin rule collection from the parent AVNM."
  type        = bool
  default     = true
}
