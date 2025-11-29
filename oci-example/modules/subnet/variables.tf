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
