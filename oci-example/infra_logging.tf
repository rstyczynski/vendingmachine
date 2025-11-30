module "log_groups" {
  source   = "./modules/log_group"
  for_each = var.log_groups

  log_group_fqrn = each.key # Log group FQRN is the map key (e.g., "log_group://vm_demo/demo/demo_log_group")
  fqrn_map       = local.compartments_fqrns # Pass compartment FQRNs - Terraform auto-infers dependency on module.compartments
  description    = each.value.description

  # depends_on not needed: local.compartments_fqrns = module.compartments.fqrn_map creates automatic dependency
}

output "log_groups" {
  description = "Log group details"
  value = {
    for k, m in module.log_groups : k => {
      id   = m.id
      name = m.name
    }
  }
}

variable "log_groups" {
  description = "Map of log groups, indexed by log group FQRN (e.g., log_group://vm_demo/demo/demo_log_group)"
  type = map(object({
    description = optional(string) # Log group description
  }))
  default = {}
}
