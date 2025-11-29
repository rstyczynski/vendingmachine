# ═══════════════════════════════════════════════════════════════
# APP2 Variables
# ═══════════════════════════════════════════════════════════════

variable "app2_nsgs" {
  description = "Map of APP2 Network Security Groups, indexed by NSG FQRN"
  type = map(object({
    rules = map(object({
      direction        = string
      protocol         = string
      source           = optional(string)
      source_type      = optional(string)
      destination      = optional(string)
      destination_type = optional(string)
      description      = optional(string)
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
      icmp_options = optional(object({
        type = number
        code = optional(number)
      }))
    }))
  }))
  default = {}
}

variable "app2_compute_instances" {
  description = "Map of APP2 compute instances, indexed by instance FQRN"
  type = map(object({
    zone = string                    # Zone map key reference (for AD only, subnet is shared)
    nsg  = optional(list(string), []) # NSG FQRN list: nsg://... (co-resource)
    spec = object({
      shape                   = optional(string, "VM.Standard.E4.Flex")
      ocpus                   = optional(number, 1)
      memory_in_gbs           = optional(number, 16)
      assign_public_ip        = optional(bool, true)
      ssh_public_key          = string
      source_image_id         = optional(string)
      boot_volume_size_in_gbs = optional(number, 50)
    })
  }))
  default = {}
}

