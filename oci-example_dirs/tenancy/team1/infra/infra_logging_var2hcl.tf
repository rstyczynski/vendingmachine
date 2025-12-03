# ═══════════════════════════════════════════════════════════════
# Variable Proxy Layer: Logging (Log Groups)
# Transforms variables into locals for use by modules/resources
# This layer can be modified to augment variables using HCL methods
# ═══════════════════════════════════════════════════════════════

locals {
  # Proxy layer: Transform log group variables into locals
  log_groups_var2hcl = {
    for k, v in var.log_groups : k => {
      log_group_fqrn = k # Log group FQRN is the map key (e.g., "log_group://team1/demo_log_group")
      description    = v.description
    }
  }
}

