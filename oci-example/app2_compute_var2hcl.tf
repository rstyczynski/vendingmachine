# ═══════════════════════════════════════════════════════════════
# Variable Proxy Layer: APP2 Compute Instances
# Transforms variables into locals for use by modules/resources
# This layer can be modified to augment variables using HCL methods
# ═══════════════════════════════════════════════════════════════

# Default var2hcl transformation logic
locals {
  # Default proxy layer: Transform APP2 compute instance variables into locals
  app2_compute_instances_var2hcl_default = {
    for k, v in var.app2_compute_instances : k => {
      instance_fqrn = k # Instance FQRN is the map key (e.g., "instance://vm_demo/demo/app2_instance")
      zone          = local.zones_var2hcl[v.zone].subnet # Zone is subnet FQRN
      availability_domain = local.zones_var2hcl[v.zone].ad
      nsg          = v.nsg
      spec         = v.spec
    }
  }

  # Custom var2hcl logic (optional - defined in app2_compute_var2hcl_custom.tf if needed)
  # If app2_compute_var2hcl_custom.tf exists, it should define app2_compute_instances_var2hcl_custom_override
  # which will override the default. If not defined, an empty map is used.
  app2_compute_instances_var2hcl_custom_override = try(
    local.app2_compute_instances_var2hcl_custom_override,
    {}
  )

  # Final var2hcl: Use custom override if provided, otherwise use default
  app2_compute_instances_var2hcl = length(local.app2_compute_instances_var2hcl_custom_override) > 0 ? local.app2_compute_instances_var2hcl_custom_override : local.app2_compute_instances_var2hcl_default
}

