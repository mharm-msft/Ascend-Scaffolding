variable "name" {
  description = "Child AVNM name (e.g. avnm-hub-east)."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group hosting AVNM + hub VNet."
  type        = string
}

variable "mg_id" {
  description = "Resource ID of the per-hub management group (AVNM scope)."
  type        = string
}

variable "address_space" {
  description = "CIDR for the hub VNet."
  type        = string
}

variable "max_spokes" {
  description = "Soft cap on spokes for this hub (recorded as a tag, used for monitoring)."
  type        = number
  default     = 500

  validation {
    condition     = var.max_spokes >= 1 && var.max_spokes <= 10000
    error_message = "max_spokes must be between 1 and 10000."
  }
}

variable "network_groups" {
  description = "Network Groups to create on this child AVNM."
  type        = list(string)
}

variable "tag_key" {
  description = "Tag key Azure Policy uses to add VNets to these NGs."
  type        = string
  default     = "avnmGroup"
}
