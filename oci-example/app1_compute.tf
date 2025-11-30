module "app1_compute_instances" {
  source   = "./modules/compute_instance"
  for_each = local.app1_compute_instances_var2hcl

  # Pass locals (from proxy layer), NOT variables directly
  instance_fqrn = each.value.instance_fqrn
  zone          = each.value.zone
  availability_domain = each.value.availability_domain
  nsg                     = each.value.nsg # NSG as co-resource
  spec                    = each.value.spec
  fqrn_map                = local.network_fqrns  # Includes VCN, subnet, main NSGs, and APP2 NSGs (from fqrn.tf)
  availability_domain_name = data.oci_identity_availability_domains.ads.availability_domains[each.value.availability_domain].name

  # depends_on = [
  #   module.subnets,
  #   module.app1_nsgs
  # ]
}


variable "app1_compute_instances" {
  description = "Map of APP1 compute instances to create, indexed by instance FQRN (e.g., instance://vm_demo/demo/demo_instance)"
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


