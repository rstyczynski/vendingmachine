# ═══════════════════════════════════════════════════════════════
# Variable Proxy Layer: WEB1 Compute Instances
# Transforms variables into locals for use by modules/resources
# This layer can be modified to augment variables using HCL methods
# ═══════════════════════════════════════════════════════════════

# Default var2hcl transformation logic
locals {
  # Default proxy layer: Transform WEB1 compute instance variables into locals
  web1_compute_instances_var2hcl_default = {
    for k, v in var.web1_compute_instances : k => {
      instance_fqrn = k # Instance FQRN is the map key (e.g., "instance://vm_demo/demo/web1_instance")
      zone          = local.zones_var2hcl[v.zone].subnet # Zone is subnet FQRN
      availability_domain = local.zones_var2hcl[v.zone].ad
      nsg          = v.nsg
      spec         = v.spec
    }
  }

  # Custom var2hcl logic (optional - defined in web1_compute_var2hcl_custom.tf if needed)
  # If web1_compute_var2hcl_custom.tf exists, it should define web1_compute_instances_var2hcl_custom_override
  # which will override the default. If not defined, an empty map is used.
  web1_compute_instances_var2hcl_custom_override = try(
    local.web1_compute_instances_var2hcl_custom_override,
    {}
  )

  # Final var2hcl: Use custom override if provided, otherwise use default
  web1_compute_instances_var2hcl = length(local.web1_compute_instances_var2hcl_custom_override) > 0 ? local.web1_compute_instances_var2hcl_custom_override : local.web1_compute_instances_var2hcl_default
}

