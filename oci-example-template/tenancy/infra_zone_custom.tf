# ═══════════════════════════════════════════════════════════════
# Custom Variable Proxy Layer: INFRA Zones
#
# This file is OPTIONAL. If this file exists, it will override the
# default var2hcl logic from infra_zone.tf
# ═══════════════════════════════════════════════════════════════

locals {
  # Custom proxy layer: Transform INFRA zone variables into locals
  # This will override the default var2hcl logic from infra_zone.tf
  #
  # Add your custom transformation logic here:
  # - Transform values (e.g., normalize, add defaults)
  # - Add computed fields
  # - Apply business logic rules
  # - Merge with additional data sources
  infra_zones_var2hcl_custom = {
    for k, v in var.infra_zones : k => {
      zone_fqrn    = k
      subnet_fqrn  = v.subnet_fqrn
      bastion_fqrn = v.bastion_fqrn
      ad           = v.ad
      # Example: Add custom transformations
      # custom_field = "value"
    }
  }
}
