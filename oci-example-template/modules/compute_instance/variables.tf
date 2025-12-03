variable "instance_fqrn" {
  description = "Instance FQRN (e.g., instance://vm_demo/demo/demo_instance)"
  type        = string
}

variable "zone" {
  description = "Zone FQRN (e.g., zone://vm_demo/demo/app). The subnet FQRN is resolved from the zone definition."
  type        = string # FQRN: zone://...
}

variable "nsg" {
  description = "NSG FQRN list (co-resource, not part of zone)"
  type        = list(string)
  default     = []
}

variable "zones" {
  description = "Zones map to resolve zone FQRN to subnet FQRN"
  type = map(object({
    subnet = string # Subnet FQRN
    ad     = number # Availability domain
  }))
  default = {}
}

variable "fqrn_map" {
  description = "FQRN → OCID map from previous resources"
  type        = map(string)
  default     = {}
}

variable "spec" {
  description = "Instance specification"
  type = object({
    shape                   = optional(string, "VM.Standard.E4.Flex")
    ocpus                   = optional(number, 1)
    memory_in_gbs           = optional(number, 16)
    assign_public_ip        = optional(bool, true)
    ssh_public_key          = string
    source_image_id         = optional(string)
    boot_volume_size_in_gbs = optional(number, 50)
    enable_bastion_plugin   = optional(bool, false) # Enable Oracle Cloud Agent Bastion plugin
  })
}

variable "availability_domain" {
  description = "Availability domain number (0, 1, or 2)"
  type        = number
}

variable "availability_domain_name" {
  description = "Availability domain name (resolved externally)"
  type        = string
}
