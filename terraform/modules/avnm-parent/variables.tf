variable "name" {
  description = "Parent AVNM name."
  type        = string
}

variable "location" {
  description = "Region for parent AVNM resource."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group hosting parent AVNM."
  type        = string
}

variable "root_mg_id" {
  description = "Resource ID of the root management group (scope for parent AVNM)."
  type        = string
}

variable "baseline_network_groups" {
  description = "Network Groups created on the parent AVNM."
  type        = list(string)
}

variable "enable_security_admin_baseline" {
  description = "Deploy a baseline SecurityAdmin deny-from-internet rule collection."
  type        = bool
  default     = true
}
