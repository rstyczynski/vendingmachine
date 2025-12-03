# ═══════════════════════════════════════════════════════════════
# APP1 Compute Instances
# ═══════════════════════════════════════════════════════════════

module "app1_compute_instances" {
  source   = "./modules/compute_instance"
  for_each = local.app1_compute_instances_var2hcl

  # Pass locals (from proxy layer), NOT variables directly
  instance_fqrn = each.value.instance_fqrn
  zone          = each.value.zone # Zone FQRN (e.g., zone://team1/app1/app)
  availability_domain = each.value.availability_domain
  nsg                     = each.value.nsg # NSG as co-resource
  spec                    = each.value.spec
  zones                   = local.infra_zones_fqrns # Zones map to resolve zone FQRN to subnet FQRN
  fqrn_map                = local.network_fqrns  # Includes VCN, subnet, all NSGs (from terraform_fqrn.tf)
  availability_domain_name = data.oci_identity_availability_domains.ads.availability_domains[each.value.availability_domain].name

  depends_on = [
    module.subnets
  ]
}

# ═══════════════════════════════════════════════════════════════
# APP1 Compute Variables
# ═══════════════════════════════════════════════════════════════

variable "app1_compute_instances" {
  description = "Map of APP1 compute instances to create, indexed by instance FQRN (e.g., instance://team1/app1/app1_instance)"
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
  # Default proxy layer: Transform APP1 compute instance variables into locals
  app1_compute_instances_var2hcl_default = {
    for k, v in var.app1_compute_instances : k => {
      instance_fqrn = k # Instance FQRN is the map key (e.g., "instance://team1/app1/app1_instance")
      zone          = v.zone # Zone FQRN (e.g., zone://team1/app1/app)
      availability_domain = module.infra_zones[v.zone].ad
      nsg          = v.nsg
      spec         = v.spec
    }
  }

  # Custom var2hcl logic (optional - defined in app1_compute_custom.tf if needed)
  # If app1_compute_custom.tf exists, it should define app1_compute_instances_var2hcl_custom
  # which will override the default. If not defined, use default.

  # Final var2hcl: Use custom override if provided (from app1_compute_custom.tf), otherwise use default
  app1_compute_instances_var2hcl = length(keys(local.app1_compute_instances_var2hcl_custom)) > 0 ? local.app1_compute_instances_var2hcl_custom : local.app1_compute_instances_var2hcl_default
}

# ═══════════════════════════════════════════════════════════════
# APP1 Compute Outputs
# ═══════════════════════════════════════════════════════════════

output "app1_compute_instances" {
  description = "APP1 Compute instance details"
  value = {
    for k, m in module.app1_compute_instances : k => {
      id         = m.id
      name       = m.name
      public_ip  = m.public_ip
      private_ip = m.private_ip
      state      = m.state
    }
  }
}
