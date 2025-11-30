module "app1_nsgs" {
  source   = "./modules/nsg"
  for_each = local.app1_nsgs_var2hcl

  # Pass locals (from proxy layer), NOT variables directly
  nsg_fqrn = each.value.nsg_fqrn
  fqrn_map = local.network_fqrns_base # Pass base network FQRNs (VCN, subnet - excludes app NSGs to avoid cycle)
  rules    = each.value.rules

  # depends_on not needed: local.network_fqrns_base depends on module.compartments, module.vcns, module.subnets
  # All dependencies are automatically inferred from fqrn_map references
}


variable "app1_nsgs" {
  description = "Map of APP1 Network Security Groups, indexed by NSG FQRN"
  type = map(object({
    rules = map(object({
      direction        = string
      protocol         = string
      source           = optional(string)
      source_type      = optional(string)
      destination      = optional(string)
      destination_type = optional(string)
      description      = optional(string)
      tcp_options = optional(object({
        destination_port_min = optional(number)
        destination_port_max = optional(number)
        source_port_min      = optional(number)
        source_port_max      = optional(number)
      }))
      udp_options = optional(object({
        destination_port_min = optional(number)
        destination_port_max = optional(number)
        source_port_min      = optional(number)
        source_port_max      = optional(number)
      }))
      icmp_options = optional(object({
        type = number
        code = optional(number)
      }))
    }))
  }))
  default = {}
}


output "app1_nsgs" {
  description = "APP1 Network Security Group details"
  value = {
    for k, m in module.app1_nsgs : k => {
      id    = m.id
      name  = m.name
      rules = m.rules
    }
  }
}

