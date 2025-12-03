# ═══════════════════════════════════════════════════════════════
# APP2 Network Security Groups
# ═══════════════════════════════════════════════════════════════

module "app2_nsgs" {
  source   = "./modules/nsg"
  for_each = local.app2_nsgs_var2hcl

  # Pass locals (from proxy layer), NOT variables directly
  nsg_fqrn = each.value.nsg_fqrn
  fqrn_map = local.network_fqrns_base # Pass base network FQRNs (VCN, subnet - excludes app NSGs to avoid cycle)
  rules    = each.value.rules

  # depends_on not needed: local.network_fqrns_base depends on module.compartments, module.vcns, module.subnets
  # All dependencies are automatically inferred from fqrn_map references
}

# ═══════════════════════════════════════════════════════════════
# APP2 NSG Variables
# ═══════════════════════════════════════════════════════════════

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

# Default var2hcl transformation logic
locals {
  # Default proxy layer: Transform APP2 NSG variables into locals
  app2_nsgs_var2hcl_default = {
    for k, v in var.app2_nsgs : k => {
      nsg_fqrn = k # NSG FQRN is the map key (e.g., "nsg://vm_demo/demo/demo_vcn/app2_web")
      rules    = v.rules
    }
  }

  # Custom var2hcl logic (optional - defined in app2_nsg_custom.tf if needed)
  # If app2_nsg_custom.tf exists, it should define app2_nsgs_var2hcl_custom
  # which will override the default. If not defined, use default.

  # Final var2hcl: Use custom override if provided (from app2_nsg_custom.tf), otherwise use default
  app2_nsgs_var2hcl = length(keys(local.app2_nsgs_var2hcl_custom)) > 0 ? local.app2_nsgs_var2hcl_custom : local.app2_nsgs_var2hcl_default
}

# ═══════════════════════════════════════════════════════════════
# APP2 NSG Outputs
# ═══════════════════════════════════════════════════════════════

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

