# ═══════════════════════════════════════════════════════════════
# INFRA1 Zone Module Instances
# Logical groupings of subnet, availability domain, and bastion
#
# OWNERSHIP: Zone does NOT create subnets or bastions.
#            These resources must exist in advance.
# ═══════════════════════════════════════════════════════════════

module "infra1_zones" {
  source   = "./modules/zone"
  for_each = local.infra1_zones_var2hcl

  # Pass locals (from proxy layer), NOT variables directly
  zone_fqrn    = each.key
  subnet_fqrn  = each.value.subnet_fqrn
  bastion_fqrn = each.value.bastion_fqrn
  ad           = each.value.ad
  fqrn_map     = local.infra_fqrns # Infrastructure FQRNs: compartments, VCN, subnet, bastion (from terraform_fqrn.tf)

  depends_on = [
    module.subnets,
    module.bastions
  ]
}

# ═══════════════════════════════════════════════════════════════
# INFRA1 Zone Variables
# ═══════════════════════════════════════════════════════════════

variable "infra1_zones" {
  description = "Map of INFRA1 zones to create, indexed by zone FQRN (e.g., zone://vm_demo/demo/app)"
  type = map(object({
    subnet_fqrn  = string           # Subnet FQRN: sub://compartment_path/vcn_name/subnet_name
    bastion_fqrn = optional(string) # Bastion FQRN: bastion://compartment_path/bastion_name
    ad           = number           # Availability domain: 0, 1, or 2
  }))
  default = {}
}

# Default var2hcl transformation logic
locals {
  # Default proxy layer: Transform INFRA1 zone variables into locals
  infra1_zones_var2hcl_default = {
    for k, v in local.infra1_zones_var2hcl_custom : k => {
      zone_fqrn    = k
      subnet_fqrn  = v.subnet_fqrn
      bastion_fqrn = v.bastion_fqrn
      ad           = v.ad
    }
  }

  # Custom var2hcl logic (optional - defined in infra1_zone_custom.tf if needed)
  # If infra1_zone_custom.tf exists, it should define infra1_zones_var2hcl_custom
  # which will override the default. If not defined, use default.

  # Final var2hcl: Use custom override if provided (from infra1_zone_custom.tf), otherwise use default
  infra1_zones_var2hcl = length(keys(local.infra1_zones_var2hcl_custom)) > 0 ? local.infra1_zones_var2hcl_custom : local.infra1_zones_var2hcl_default
}

# ═══════════════════════════════════════════════════════════════
# INFRA1 Zone Outputs
# ═══════════════════════════════════════════════════════════════

output "infra1_zones" {
  description = "INFRA1 Zone details"
  value = {
    for k, m in module.infra1_zones : k => {
      zone_fqrn        = m.zone_fqrn
      name             = m.name
      compartment_fqrn = m.compartment_fqrn
      compartment_id   = m.compartment_id
      subnet_fqrn      = m.subnet_fqrn
      subnet_id        = m.subnet_id
      bastion_fqrn     = m.bastion_fqrn
      bastion_id       = m.bastion_id
      ad               = m.ad
    }
  }
}

# Aggregated INFRA1 zones map for compute instances
output "infra1_zones_map" {
  description = "INFRA1 Zones map compatible with compute_instance module"
  value = merge([
    for k, m in module.infra1_zones : m.zones_map_entry
  ]...)
}

# INFRA1 Zone FQRN map entries (for unified FQRN map aggregation)
locals {
  infra1_zone_fqrn_map = merge([
    for k, m in module.infra1_zones : m.fqrn_map
  ]...)
}
