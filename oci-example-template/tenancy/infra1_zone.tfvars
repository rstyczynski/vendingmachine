# ═══════════════════════════════════════════════════════════════
# INFRA1 Zone Configuration
# Logical groupings of subnet, availability domain, and bastion
#
# OWNERSHIP: Zone does NOT create subnets or bastions.
#            These resources must exist in advance.
# ═══════════════════════════════════════════════════════════════

infra1_zones = {
  "zone://tmp_demo1/demo1/infra1" = {
    subnet_fqrn  = "sub://tmp_demo1/demo1/subnet"     # Subnet FQRN
    bastion_fqrn = "bastion://tmp_demo1/demo1/bastion"    # Bastion FQRN (optional)
    ad           = 1                    # Availability domain: 0, 1, or 2
  }
}
