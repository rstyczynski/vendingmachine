# Unified compartments output (merge all levels, up to level 6 - OCI maximum)
locals {
  all_compartments = merge(
    module.compartment_level_1,
    module.compartment_level_2,
    module.compartment_level_3,
    module.compartment_level_4,
    module.compartment_level_5,
    module.compartment_level_6
  )
}

# Output unified FQRN map from all compartment levels
output "fqrn_map" {
  description = "FQRN → OCID mapping for all compartments (including intermediate levels)"
  value = merge([
    for k, m in local.all_compartments : m.fqrn_map
  ]...)
}

# Output individual compartment details
output "compartments" {
  description = "All compartments by FQRN"
  value = {
    for k, m in local.all_compartments : k => {
      id   = m.id
      name = m.name
    }
  }
}

