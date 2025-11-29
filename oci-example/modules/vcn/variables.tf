variable "vcn_fqrn" {
  description = "VCN FQRN (e.g., vcn://vm_demo/demo/demo_vcn)"
  type        = string
}

variable "fqrn_map" {
  description = "FQRN → OCID map from previous resources"
  type        = map(string)
  default     = {}
}

variable "cidr_blocks" {
  description = "VCN CIDR blocks"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "dns_label" {
  description = "DNS label for VCN"
  type        = string
  default     = null
}

variable "create_internet_gateway" {
  description = "Create internet gateway"
  type        = bool
  default     = true
}
