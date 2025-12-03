# ═══════════════════════════════════════════════════════════════
# Custom Variable Proxy Layer: APP2 Network Security Groups
# 
# This file is OPTIONAL. If this file exists, it will override the
# default var2hcl logic from app2_nsg.tf
# ═══════════════════════════════════════════════════════════════

locals {
  # Custom proxy layer: Transform APP2 NSG variables into locals
  # This will override the default var2hcl logic from app2_nsg.tf
  # 
  # Add your custom transformation logic here:
  # - Transform values (e.g., normalize, add defaults)
  # - Add computed fields
  # - Apply business logic rules
  # - Merge with additional data sources
  app2_nsgs_var2hcl_custom = {
    for k, v in var.app2_nsgs : k => {
      nsg_fqrn = k
      rules    = v.rules
      # Example: Add custom transformations
      # custom_field = "value"
    }
  }
}

