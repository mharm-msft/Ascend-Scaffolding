variable "location" {
  type        = string
  description = "Azure region."
}

variable "resource_group_name" {
  type        = string
  description = "Target resource group for the spoke."
}

variable "create_resource_group" {
  type        = bool
  description = "Create the resource group (true) or assume it already exists (false)."
  default     = true
}

variable "vnet_name" {
  type        = string
  description = "Name of the spoke VNet."
}

variable "address_space" {
  type        = list(string)
  description = "VNet CIDR(s)."
}

variable "avnm_group_tag_key" {
  type        = string
  description = "Tag key that drives AVNM Network Group membership. Must match the platform-wide setting."
  default     = "avnmGroup"
}

variable "avnm_group_tag_value" {
  type        = string
  description = "Tag value identifying which Network Group this spoke joins (e.g. east-prod-spokes)."

  validation {
    condition     = length(var.avnm_group_tag_value) > 0 && !can(regex("^hub-", var.avnm_group_tag_value))
    error_message = "avnm_group_tag_value must be non-empty and must not start with 'hub-' (reserved for hub VNets)."
  }
}

variable "subnets" {
  description = "Subnets to create."
  type = list(object({
    name   = string
    prefix = string
  }))
  default = []
}

variable "create_baseline_nsg" {
  type        = bool
  description = "Create a baseline NSG and attach it to every subnet."
  default     = true
}

variable "extra_tags" {
  type        = map(string)
  description = "Additional tags merged on top of the AVNM membership tag."
  default     = {}
}
