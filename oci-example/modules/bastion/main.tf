# ═══════════════════════════════════════════════════════════════
# Variable Proxy Layer
# Transforms variables into locals for use by resources
# This layer can be modified to augment variables using HCL methods
# ═══════════════════════════════════════════════════════════════

locals {
  # Parse bastion FQRN: bastion://compartment_path/bastion_name
  bastion_fqrn_parts = regex("^bastion://(.+)/([^/]+)$", var.bastion_fqrn)
  compartment_path   = local.bastion_fqrn_parts[0]  # Extract compartment path from bastion FQRN (e.g., "vm_demo/demo")
  bastion_name       = local.bastion_fqrn_parts[1]  # Extract bastion name from bastion FQRN

  # Derive compartment FQRN from bastion FQRN (following FQRN scheme rules)
  # Compartment FQRN format: cmp:///compartment_path (with leading slash to match compartment module output)
  compartment_fqrn = "cmp:///${local.compartment_path}"

  # Resolve FQRNs to OCIDs
  compartment_id  = var.fqrn_map[local.compartment_fqrn]
  target_subnet_id = var.fqrn_map[var.target_subnet_fqrn]

  # Proxy layer: Transform variables into locals (augment as needed)
  bastion_config = {
    bastion_type                  = var.bastion_type
    client_cidr_block_allow_list  = var.client_cidr_block_allow_list
    max_session_ttl_in_seconds    = var.max_session_ttl_in_seconds
    dns_proxy_status              = var.dns_proxy_status
  }
}

# ═══════════════════════════════════════════════════════════════
# Resource uses locals from proxy layer, NOT variables directly
# ═══════════════════════════════════════════════════════════════

resource "oci_bastion_bastion" "this" {
  compartment_id        = local.compartment_id
  target_subnet_id     = local.target_subnet_id
  bastion_type         = local.bastion_config.bastion_type
  name                 = local.bastion_name  # Use bastion name extracted from FQRN
  client_cidr_block_allow_list = local.bastion_config.client_cidr_block_allow_list
  max_session_ttl_in_seconds   = local.bastion_config.max_session_ttl_in_seconds
  dns_proxy_status             = local.bastion_config.dns_proxy_status

  freeform_tags = {
    "managed_by" = "terraform"
    "component"  = "oci-vending-machine"
  }
}

