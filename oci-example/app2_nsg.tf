module "app2_nsgs" {
  source   = "./modules/nsg"
  for_each = var.app2_nsgs

  nsg_fqrn = each.key # NSG FQRN is the map key (e.g., "nsg://vm_demo/demo/demo_vcn/app2_web")
  fqrn_map = local.network_fqrns_base # Pass base network FQRNs (VCN, subnet - excludes app NSGs to avoid cycle)
  rules    = each.value.rules

  depends_on = [module.subnets]
}


variable "app2_nsgs" {
  description = "Map of APP2 Network Security Groups, indexed by NSG FQRN"
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


output "app2_nsgs" {
  description = "APP2 Network Security Group details"
  value = {
    for k, m in module.app2_nsgs : k => {
      id    = m.id
      name  = m.name
      rules = m.rules
    }
  }
}
