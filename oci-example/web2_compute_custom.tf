# ═══════════════════════════════════════════════════════════════
# Custom Variable Proxy Layer: WEB2 Compute Instances
# 
# This file is OPTIONAL. Copy this file to web2_compute_var2hcl_custom.tf
# and customize the var2hcl transformation logic as needed.
#
# When this file exists and defines web2_compute_instances_var2hcl_custom_override,
# it will override the default var2hcl logic from web2_compute_var2hcl.tf
# ═══════════════════════════════════════════════════════════════

locals {
  # Custom proxy layer: Transform WEB2 compute instance variables into locals
  # This will override the default var2hcl logic from web2_compute_var2hcl.tf
  # 
  # Add your custom transformation logic here:
  # - Transform values (e.g., normalize, uppercase, add defaults)
  # - Add computed fields
  # - Apply business logic rules
  # - Merge with additional data sources
  web2_compute_instances_var2hcl_custom_override = {
    for k, v in var.web2_compute_instances : k => {
      instance_fqrn = k
      zone          = local.zones_var2hcl[v.zone].subnet
      availability_domain = local.zones_var2hcl[v.zone].ad
      nsg          = v.nsg
      spec         = merge(v.spec, {
        # Example: Add custom transformations
        # enable_bastion_plugin = true  # Force enable bastion plugin for all instances
        # shape = "VM.Standard.E4.Flex"  # Override shape for all instances
      })
    }
  }
}

