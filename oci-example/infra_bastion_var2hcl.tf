# ═══════════════════════════════════════════════════════════════
# Variable Proxy Layer: Bastions
# Transforms variables into locals for use by modules/resources
# This layer can be modified to augment variables using HCL methods
# ═══════════════════════════════════════════════════════════════

locals {
  # Proxy layer: Transform variables into locals
  bastions_var2hcl = {
    for k, v in var.bastions : k => {
      bastion_fqrn        = k # Bastion FQRN is the map key (e.g., "bastion://vm_demo/demo/demo_bastion")
      target_subnet_fqrn  = v.target_subnet_fqrn # Subnet FQRN that bastion connects to
      bastion_type        = upper(v.bastion_type) # Normalize to uppercase (e.g., "standard" -> "STANDARD")
      client_cidr_block_allow_list = length(v.client_cidr_block_allow_list) > 0 ? v.client_cidr_block_allow_list : ["0.0.0.0/0"] # Default to allow all if empty
      max_session_ttl_in_seconds  = v.max_session_ttl_in_seconds
      dns_proxy_status            = upper(v.dns_proxy_status) # Normalize to uppercase
    }
  }
}

