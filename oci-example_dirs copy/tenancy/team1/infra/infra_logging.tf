module "log_groups" {
  source   = "./modules/log_group"
  for_each = local.log_groups_var2hcl

  # Pass locals (from proxy layer), NOT variables directly
  log_group_fqrn = each.value.log_group_fqrn
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
