variable "avnm_id" {
  description = "Resource ID of the AVNM to attach SecurityAdmin configuration to."
  type        = string
}

variable "applies_to_network_group_ids" {
  description = "Resource IDs of Network Groups this rule collection applies to."
  type        = list(string)
}

variable "collection_name" {
  description = "Rule collection name."
  type        = string
  default     = "baseline-deny-from-internet"
}
