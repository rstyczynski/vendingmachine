# ═══════════════════════════════════════════════════════════════
# APP1 Network Security Groups
# ═══════════════════════════════════════════════════════════════

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

# ═══════════════════════════════════════════════════════════════
# APP1 NSG Variables
# ═══════════════════════════════════════════════════════════════

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

# Default var2hcl transformation logic
locals {
  # Default proxy layer: Transform APP1 NSG variables into locals
  app1_nsgs_var2hcl_default = {
    for k, v in var.app1_nsgs : k => {
      nsg_fqrn = k # NSG FQRN is the map key (e.g., "nsg://vm_demo/demo/demo_vcn/app1_web")
      rules    = v.rules
    }
  }

  # Custom var2hcl logic (optional - defined in app1_nsg_custom.tf if needed)
  # If app1_nsg_custom.tf exists, it should define app1_nsgs_var2hcl_custom
  # which will override the default. If not defined, use default.

  # Final var2hcl: Use custom override if provided (from app1_nsg_custom.tf), otherwise use default
  app1_nsgs_var2hcl = length(keys(local.app1_nsgs_var2hcl_custom)) > 0 ? local.app1_nsgs_var2hcl_custom : local.app1_nsgs_var2hcl_default
}

# ═══════════════════════════════════════════════════════════════
# APP1 NSG Outputs
# ═══════════════════════════════════════════════════════════════

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

