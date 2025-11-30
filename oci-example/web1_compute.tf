# ═══════════════════════════════════════════════════════════════
# WEB1 Compute Instances
# ═══════════════════════════════════════════════════════════════

module "web1_compute_instances" {
  source   = "./modules/compute_instance"
  for_each = var.web1_compute_instances

  instance_fqrn = each.key # Instance FQRN is the map key (e.g., "instance://vm_demo/demo/web1_instance")
  zone          = var.zones[each.value.zone].subnet # Zone is subnet FQRN
  availability_domain = var.zones[each.value.zone].ad
  nsg                     = each.value.nsg # NSG as co-resource
  spec                    = each.value.spec
  fqrn_map                = local.network_fqrns  # Includes VCN, subnet, all NSGs (from terraform_fqrn.tf)
  availability_domain_name = data.oci_identity_availability_domains.ads.availability_domains[var.zones[each.value.zone].ad].name

  depends_on = [
    module.subnets
  ]
}

# ═══════════════════════════════════════════════════════════════
# WEB1 Compute Variables
# ═══════════════════════════════════════════════════════════════

variable "web1_compute_instances" {
  description = "Map of WEB1 compute instances to create, indexed by instance FQRN (e.g., instance://vm_demo/demo/web1_instance)"
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
    })
  }))
  default = {}
}

# ═══════════════════════════════════════════════════════════════
# WEB1 Compute Outputs
# ═══════════════════════════════════════════════════════════════

output "web1_compute_instances" {
  description = "WEB1 Compute instance details"
  value = {
    for k, m in module.web1_compute_instances : k => {
      id         = m.id
      name       = m.name
      public_ip  = m.public_ip
      private_ip = m.private_ip
      state      = m.state
    }
  }
}
