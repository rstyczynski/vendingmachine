# ═══════════════════════════════════════════════════════════════
# Custom Variable Proxy Layer: APP3 Compute Instances
# 
# This file is OPTIONAL. If this file exists, it will override the
# default var2hcl logic from app3_compute.tf
# ═══════════════════════════════════════════════════════════════

locals {
  # Custom proxy layer: Transform APP3 compute instance variables into locals
  # This will override the default var2hcl logic from app3_compute.tf
  # 
  # Add your custom transformation logic here:
  # - Transform values (e.g., normalize, uppercase, add defaults)
  # - Add computed fields
  # - Apply business logic rules
  # - Merge with additional data sources
  app3_compute_instances_var2hcl_custom = {
    for k, v in var.app3_compute_instances : k => {
      instance_fqrn = k
      zone          = v.zone # Zone FQRN (e.g., zone://vm_demo/demo/app)
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

