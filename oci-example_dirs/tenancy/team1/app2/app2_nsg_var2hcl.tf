# ═══════════════════════════════════════════════════════════════
# Variable Proxy Layer: APP2 Network Security Groups
# Transforms variables into locals for use by modules/resources
# This layer can be modified to augment variables using HCL methods
# ═══════════════════════════════════════════════════════════════

locals {
  # Proxy layer: Transform APP2 NSG variables into locals
  app2_nsgs_var2hcl = {
    for k, v in var.app2_nsgs : k => {
      nsg_fqrn = k # NSG FQRN is the map key (e.g., "nsg://team1/app2/demo_vcn/app2_web")
      rules    = v.rules
    }
  }
}

