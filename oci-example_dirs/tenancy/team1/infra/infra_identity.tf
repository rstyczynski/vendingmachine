module "compartments" {
  source = "./modules/compartments"

  tenancy_ocid = local.tenancy_ocid
  compartments = local.compartments_var2hcl # Pass locals (from proxy layer), NOT variables directly
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
