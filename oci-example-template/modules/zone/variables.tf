# ═══════════════════════════════════════════════════════════════
# Zone Module Variables
# ═══════════════════════════════════════════════════════════════

variable "zone_fqrn" {
  description = "Zone FQRN (e.g., zone://vm_demo/demo/app)"
  type        = string

  validation {
    condition     = can(regex("^zone://(.+)/([^/]+)$", var.zone_fqrn))
    error_message = "zone_fqrn must match pattern: zone://compartment_path/zone_name"
  }
}

variable "subnet_fqrn" {
  description = "Subnet FQRN for this zone (e.g., sub://vm_demo/demo/demo_vcn/subnet)"
  type        = string

  validation {
    condition     = can(regex("^sub://(.+)/([^/]+)/([^/]+)$", var.subnet_fqrn))
    error_message = "subnet_fqrn must match pattern: sub://compartment_path/vcn_name/subnet_name"
  }
}

variable "bastion_fqrn" {
  description = "Bastion FQRN for secure access to resources in this zone (e.g., bastion://vm_demo/demo/demo_bastion)"
  type        = string
  default     = null

  validation {
    condition     = var.bastion_fqrn == null || can(regex("^bastion://(.+)/([^/]+)$", var.bastion_fqrn))
    error_message = "bastion_fqrn must match pattern: bastion://compartment_path/bastion_name"
  }
}

variable "ad" {
  description = "Availability domain number (0, 1, or 2)"
  type        = number

  validation {
    condition     = var.ad >= 0 && var.ad <= 2
    error_message = "ad must be 0, 1, or 2"
  }
}

variable "fqrn_map" {
  description = "FQRN → OCID map from previous resources (used to resolve subnet and bastion FQRNs)"
  type        = map(string)
  default     = {}
}

