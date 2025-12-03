# ═══════════════════════════════════════════════════════════════
# Variable Proxy Layer: Identity (Compartments and Zones)
# Transforms variables into locals for use by modules/resources
# This layer can be modified to augment variables using HCL methods
# ═══════════════════════════════════════════════════════════════

locals {
  # Proxy layer: Transform compartment variables into locals
  compartments_var2hcl = var.compartments

}

