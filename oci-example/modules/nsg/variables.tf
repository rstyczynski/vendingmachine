variable "nsg_fqrn" {
  description = "NSG FQRN (e.g., nsg://vm_demo/demo/demo_vcn/ssh)"
  type        = string
}

variable "compartment_fqrn" {
  description = "Compartment FQRN (deprecated - derived from nsg_fqrn)"
  type        = string
  default     = null
}

variable "vcn_fqrn" {
  description = "VCN FQRN (deprecated - derived from nsg_fqrn)"
  type        = string
  default     = null
}

variable "fqrn_map" {
  description = "FQRN → OCID map from previous resources"
  type        = map(string)
  default     = {}
}

variable "rules" {
  description = "Map of security rules"
  type = map(object({
    direction   = string                    # INGRESS or EGRESS
    protocol    = string                    # "6" (TCP), "17" (UDP), "1" (ICMP), "all"
    source      = optional(string)          # For INGRESS
    destination = optional(string)          # For EGRESS
    source_type = optional(string, "CIDR_BLOCK")
    destination_type = optional(string, "CIDR_BLOCK")
    description = optional(string)

    # TCP/UDP options
    tcp_options = optional(object({
      destination_port_min = optional(number)
      destination_port_max = optional(number)
      source_port_min      = optional(number)
      source_port_max      = optional(number)
    }))

    udp_options = optional(object({
      destination_port_min = optional(number)
      destination_port_max = optional(number)
      source_port_min      = optional(number)
      source_port_max      = optional(number)
    }))

    # ICMP options
    icmp_options = optional(object({
      type = number
      code = optional(number)
    }))
  }))
  default = {}
}
