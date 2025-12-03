# ═══════════════════════════════════════════════════════════════
# Zone Module
# Logical grouping of subnet, availability domain, and bastion
# Zone is a configuration module - it doesn't create OCI resources
# but provides a unified context for compute instances
# ═══════════════════════════════════════════════════════════════

locals {
  # Parse zone FQRN: zone://compartment_path/zone_name
  # Example: zone://vm_demo/demo/app
  zone_fqrn_parts  = regex("^zone://(.+)/([^/]+)$", var.zone_fqrn)
  compartment_path = local.zone_fqrn_parts[0] # Extract compartment path (e.g., "vm_demo/demo")
  zone_name        = local.zone_fqrn_parts[1] # Extract zone name (e.g., "app")

  # Derive compartment FQRN from zone FQRN
  # Compartment FQRN format: cmp:///compartment_path (with leading slash to match compartment module output)
  compartment_fqrn = "cmp:///${local.compartment_path}"

  # Resolve FQRNs to OCIDs (compartment, subnet, and bastion)
  compartment_id = var.fqrn_map[local.compartment_fqrn]
  subnet_id      = var.fqrn_map[var.subnet_fqrn]
  bastion_id     = var.bastion_fqrn != null ? lookup(var.fqrn_map, var.bastion_fqrn, null) : null

  # Parse subnet FQRN to extract VCN info: sub://compartment_path/vcn_name/subnet_name
  subnet_fqrn_parts = regex("^sub://(.+)/([^/]+)/([^/]+)$", var.subnet_fqrn)
  subnet_vcn_name   = local.subnet_fqrn_parts[1]
  subnet_name       = local.subnet_fqrn_parts[2]

  # Zone configuration object - aggregates all zone-related information
  zone_config = {
    zone_fqrn        = var.zone_fqrn
    zone_name        = local.zone_name
    compartment_fqrn = local.compartment_fqrn
    compartment_id   = local.compartment_id
    subnet_fqrn      = var.subnet_fqrn
    subnet_id        = local.subnet_id
    bastion_fqrn     = var.bastion_fqrn
    bastion_id       = local.bastion_id
    ad               = var.ad
    vcn_name         = local.subnet_vcn_name
    subnet_name      = local.subnet_name
  }
}

# ═══════════════════════════════════════════════════════════════
# Zone is a logical construct - no OCI resources are created
# The module serves as a configuration aggregator that:
# 1. Parses and validates zone FQRN
# 2. Resolves subnet and bastion references
# 3. Provides unified zone configuration for consumers
# ═══════════════════════════════════════════════════════════════

