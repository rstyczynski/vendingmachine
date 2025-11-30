# ═══════════════════════════════════════════════════════════════
# Variable Proxy Layer: APP1 Network Security Groups
# Transforms variables into locals for use by modules/resources
# This layer can be modified to augment variables using HCL methods
# ═══════════════════════════════════════════════════════════════

locals {
  # Proxy layer: Transform APP1 NSG variables into locals
  app1_nsgs_var2hcl = {
    for k, v in var.app1_nsgs : k => {
      nsg_fqrn = k # NSG FQRN is the map key (e.g., "nsg://vm_demo/demo/demo_vcn/ssh")
      rules    = v.rules
    }
  }
}

