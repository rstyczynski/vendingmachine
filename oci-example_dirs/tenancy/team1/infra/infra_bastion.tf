# ═══════════════════════════════════════════════════════════════
# Infrastructure Bastions
# Bastion service - provides secure access to private resources
# ═══════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════
# LAYER 4: Bastions (depends on compartments + subnets)
# ═══════════════════════════════════════════════════════════════

module "bastions" {
  source   = "./modules/bastion"
  for_each = local.bastions_var2hcl

  # Pass locals (from proxy layer), NOT variables directly
  bastion_fqrn        = each.value.bastion_fqrn
  target_subnet_fqrn  = each.value.target_subnet_fqrn
  fqrn_map            = local.network_fqrns_base # Pass compartment + VCN + Subnet FQRNs - Terraform auto-infers dependencies
  bastion_type        = each.value.bastion_type
  client_cidr_block_allow_list = each.value.client_cidr_block_allow_list
  max_session_ttl_in_seconds  = each.value.max_session_ttl_in_seconds
  dns_proxy_status            = each.value.dns_proxy_status

  # depends_on not needed: local.network_fqrns_base depends on module.compartments, module.vcns, module.subnets
  # All dependencies are automatically inferred from fqrn_map references
}


variable "bastions" {
  description = "Map of bastions, indexed by bastion FQRN (e.g., bastion://team1/demo_bastion)"
  type = map(object({
    target_subnet_fqrn            = string           # Subnet FQRN that bastion connects to (e.g., sub://team1/demo_vcn/public_subnet)
    bastion_type                  = optional(string, "standard") # Type of bastion (standard or session)
    client_cidr_block_allow_list  = optional(list(string), [])   # CIDR blocks allowed to connect
    max_session_ttl_in_seconds    = optional(number, 10800)     # Max session TTL (default: 3 hours)
    dns_proxy_status              = optional(string, "DISABLED") # DNS proxy status (ENABLED or DISABLED)
  }))
  default = {}
}

output "bastions" {
  description = "Bastion details"
  value = {
    for k, m in module.bastions : k => {
      id    = m.id
      name  = m.name
      state = m.state
    }
  }
}


