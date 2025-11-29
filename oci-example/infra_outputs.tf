# ═══════════════════════════════════════════════════════════════
# Infrastructure Outputs
# ═══════════════════════════════════════════════════════════════

# Unified FQRN map - aggregates all resource types from all applications
output "fqrn_map" {
  description = "Unified FQRN → OCID map from all resource modules (shared + app1 + app2)"
  value       = local.unified_fqrn_map
}

# Shared infrastructure outputs
output "compartments" {
  description = "Compartment details"
  value       = module.compartments.compartments
}

output "vcns" {
  description = "VCN details"
  value = {
    for k, m in module.vcns : k => {
      id                  = m.id
      name                = m.name
      internet_gateway_id = m.internet_gateway_id
    }
  }
}

output "subnets" {
  description = "Subnet details"
  value = {
    for k, m in module.subnets : k => {
      id   = m.id
      name = m.name
    }
  }
}
