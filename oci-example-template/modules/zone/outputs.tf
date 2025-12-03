# ═══════════════════════════════════════════════════════════════
# Zone Module Outputs
# ═══════════════════════════════════════════════════════════════

output "zone_fqrn" {
  description = "Zone FQRN"
  value       = var.zone_fqrn
}

output "name" {
  description = "Zone name (extracted from FQRN)"
  value       = local.zone_name
}

output "compartment_fqrn" {
  description = "Compartment FQRN (derived from zone FQRN)"
  value       = local.compartment_fqrn
}

output "compartment_id" {
  description = "Compartment OCID (resolved from compartment FQRN)"
  value       = local.compartment_id
}

output "subnet_fqrn" {
  description = "Subnet FQRN for this zone"
  value       = var.subnet_fqrn
}

output "subnet_id" {
  description = "Subnet OCID (resolved from subnet FQRN)"
  value       = local.subnet_id
}

output "bastion_fqrn" {
  description = "Bastion FQRN for this zone"
  value       = var.bastion_fqrn
}

output "bastion_id" {
  description = "Bastion OCID (resolved from bastion FQRN)"
  value       = local.bastion_id
}

output "ad" {
  description = "Availability domain number"
  value       = var.ad
}

output "vcn_name" {
  description = "VCN name (extracted from subnet FQRN)"
  value       = local.subnet_vcn_name
}

output "subnet_name" {
  description = "Subnet name (extracted from subnet FQRN)"
  value       = local.subnet_name
}

# Zone configuration object - all zone info in one output
output "config" {
  description = "Complete zone configuration object"
  value       = local.zone_config
}

# FQRN map entry for this zone (for aggregation into unified FQRN map)
# Zone doesn't create OCI resources, so we map zone FQRN to subnet FQRN
# This allows compute instances to resolve zone -> subnet seamlessly
output "fqrn_map" {
  description = "FQRN → mapping for this zone (zone FQRN maps to zone config)"
  value = {
    (var.zone_fqrn) = {
      subnet = var.subnet_fqrn
      ad     = var.ad
    }
  }
}

# Zones map entry (compatible with compute_instance module zones variable)
output "zones_map_entry" {
  description = "Zone entry compatible with compute_instance zones variable"
  value = {
    (var.zone_fqrn) = {
      subnet = var.subnet_fqrn
      ad     = var.ad
    }
  }
}

