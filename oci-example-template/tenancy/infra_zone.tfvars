# ═══════════════════════════════════════════════════════════════
# INFRA Zone Configuration
# Logical groupings of subnet, availability domain, and bastion
#
# OWNERSHIP: Zone does NOT create subnets or bastions.
#            These resources must exist in advance.
# ═══════════════════════════════════════════════════════════════

infra_zones = {
  "zone://tmp_demo/demo/infra" = {
    subnet_fqrn  = "sub://tmp_demo/demo/subnet"     # Subnet FQRN
    bastion_fqrn = "bastion://tmp_demo/demo/bastion"    # Bastion FQRN (optional)
    ad           = 2                    # Availability domain: 0, 1, or 2
  }
}
