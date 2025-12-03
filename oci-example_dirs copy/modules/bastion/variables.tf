variable "bastion_fqrn" {
  description = "Bastion FQRN (e.g., bastion://vm_demo/demo/demo_bastion)"
  type        = string
}

variable "target_subnet_fqrn" {
  description = "Target subnet FQRN that the bastion connects to (e.g., sub://vm_demo/demo/demo_vcn/public_subnet)"
  type        = string
}

variable "fqrn_map" {
  description = "FQRN → OCID map from previous resources"
  type        = map(string)
  default     = {}
}

variable "bastion_type" {
  description = "Type of bastion (standard or session)"
  type        = string
  default     = "standard"
}

variable "client_cidr_block_allow_list" {
  description = "A list of CIDR blocks that are allowed to connect to sessions hosted by this bastion"
  type        = list(string)
  default     = []
}

variable "max_session_ttl_in_seconds" {
  description = "The maximum amount of time that any session on the bastion can remain active (in seconds)"
  type        = number
  default     = 10800  # 3 hours
}

variable "dns_proxy_status" {
  description = "Flag to enable FQDN and SOCKS5 Proxy Support (ENABLED or DISABLED)"
  type        = string
  default     = "DISABLED"
}

