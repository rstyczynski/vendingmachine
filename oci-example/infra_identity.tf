module "compartments" {
  source = "./modules/compartments"

  tenancy_ocid = local.tenancy_ocid
  compartments = var.compartments
}


variable "zones" {
  description = "Shared zones (location contexts) used by all applications"
  type = map(object({
    # compartment is optional because it is in FQRN URI already
    compartment = optional(string) # FQRN: cmp://...
    subnet      = string # FQRN: sub://...
    # ad is a number that is mapped to the availability domain name
    ad          = number # Availability domain: 0, 1, or 2
  }))
  default = {}
}

variable "compartments" {
  description = "Map of compartments to create"
  type = map(object({
    description   = string
    enable_delete = optional(bool, false)
  }))
  default = {}
}

output "compartments" {
  description = "Compartment details"
  value       = module.compartments.compartments
}

# Unified FQRN map - aggregates all resource types from all applications
output "fqrn_map" {
  description = "Unified FQRN → OCID map from all resource modules (shared + app1 + app2)"
  value       = local.unified_fqrn_map
}
