variable "subnet_fqrn" {
  description = "Subnet FQRN (e.g., sub://vm_demo/demo/demo_vcn/public_subnet)"
  type        = string
}

variable "fqrn_map" {
  description = "FQRN → OCID map from previous resources"
  type        = map(string)
  default     = {}
}

variable "cidr_block" {
  description = "Subnet CIDR block"
  type        = string
}

variable "dns_label" {
  description = "DNS label for subnet"
  type        = string
  default     = null
}

variable "prohibit_public_ip_on_vnic" {
  description = "Prohibit public IP on VNIC"
  type        = bool
  default     = false
}

variable "route_table_id" {
  description = "Optional route table ID to associate with subnet (e.g., service gateway route table for private subnets)"
  type        = string
  default     = null
}

variable "enable_flow_log" {
  description = "Enable VCN flow logs for this subnet"
  type        = bool
  default     = false
}

variable "flow_log_display_name" {
  description = "Display name for the flow log (defaults to subnet name + '-flow-log')"
  type        = string
  default     = null
}

variable "flow_log_log_group_id" {
  description = "OCID of the log group where flow logs will be stored (required if enable_flow_log is true). Can be provided directly or via flow_log_log_group_fqrn."
  type        = string
  default     = null
}

variable "flow_log_log_group_fqrn" {
  description = "FQRN of the log group where flow logs will be stored (e.g., log_group://vm_demo/demo/demo_log_group). Alternative to flow_log_log_group_id."
  type        = string
  default     = null
}
