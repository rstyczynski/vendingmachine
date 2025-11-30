# ═══════════════════════════════════════════════════════════════
# WEB2 Compute Instances
# ═══════════════════════════════════════════════════════════════

module "web2_compute_instances" {
  source   = "./modules/compute_instance"
  for_each = local.web2_compute_instances_var2hcl

  # Pass locals (from proxy layer), NOT variables directly
  instance_fqrn = each.value.instance_fqrn
  zone          = each.value.zone
  availability_domain = each.value.availability_domain
  nsg                     = each.value.nsg # NSG as co-resource
  spec                    = each.value.spec
  fqrn_map                = local.network_fqrns  # Includes VCN, subnet, all NSGs (from terraform_fqrn.tf)
  availability_domain_name = data.oci_identity_availability_domains.ads.availability_domains[each.value.availability_domain].name

  depends_on = [
    module.subnets
  ]
}

# ═══════════════════════════════════════════════════════════════
# WEB2 Compute Variables
# ═══════════════════════════════════════════════════════════════

variable "web2_compute_instances" {
  description = "Map of WEB2 compute instances to create, indexed by instance FQRN (e.g., instance://vm_demo/demo/web2_instance)"
  type = map(object({
    zone = string                    # Zone map key reference (for subnet, AD)
    nsg  = optional(list(string), []) # NSG FQRN list: nsg://... (co-resource)
    spec = object({
      shape                   = optional(string, "VM.Standard.E4.Flex")
      ocpus                   = optional(number, 1)
      memory_in_gbs           = optional(number, 16)
      assign_public_ip        = optional(bool, true)
      ssh_public_key          = string
      source_image_id         = optional(string)
      boot_volume_size_in_gbs = optional(number, 50)
      enable_bastion_plugin   = optional(bool, false) # Enable Oracle Cloud Agent Bastion plugin
    })
  }))
  default = {}
}

# Default var2hcl transformation logic
locals {
  # Default proxy layer: Transform WEB2 compute instance variables into locals
  web2_compute_instances_var2hcl_default = {
    for k, v in var.web2_compute_instances : k => {
      instance_fqrn = k # Instance FQRN is the map key (e.g., "instance://vm_demo/demo/web2_instance")
      zone          = local.zones_var2hcl[v.zone].subnet # Zone is subnet FQRN
      availability_domain = local.zones_var2hcl[v.zone].ad
      nsg          = v.nsg
      spec         = v.spec
    }
  }

  # Custom var2hcl logic (optional - defined in web2_compute_var2hcl_custom.tf if needed)
  # If web2_compute_var2hcl_custom.tf exists, it should define web2_compute_instances_var2hcl_custom_override
  # which will override the default. If not defined, an empty map is used.
  web2_compute_instances_var2hcl_custom_override = try(
    local.web2_compute_instances_var2hcl_custom_override,
    {}
  )

  # Final var2hcl: Use custom override if provided, otherwise use default
  web2_compute_instances_var2hcl = length(local.web2_compute_instances_var2hcl_custom_override) > 0 ? local.web2_compute_instances_var2hcl_custom_override : local.web2_compute_instances_var2hcl_default
}

# ═══════════════════════════════════════════════════════════════
# WEB2 Compute Outputs
# ═══════════════════════════════════════════════════════════════

output "web2_compute_instances" {
  description = "WEB2 Compute instance details"
  value = {
    for k, m in module.web2_compute_instances : k => {
      id         = m.id
      name       = m.name
      public_ip  = m.public_ip
      private_ip = m.private_ip
      state      = m.state
    }
  }
}
