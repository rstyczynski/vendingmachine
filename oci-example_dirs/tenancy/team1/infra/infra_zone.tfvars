# ═══════════════════════════════════════════════════════════════
# INFRA Zone Configuration
# Logical groupings of subnet, availability domain, and bastion
#
# OWNERSHIP: Zone does NOT create subnets or bastions.
#            These resources must exist in advance.
# ═══════════════════════════════════════════════════════════════

infra_zones = {
  "zone://team1/infra" = {
    subnet_fqrn  = "sub://team1/infra/demo_vcn/subnet"     # Subnet FQRN
    bastion_fqrn = "bastion://team1/infra/demo_bastion"    # Bastion FQRN (optional)
    ad           = 0                                         # Availability domain: 0, 1, or 2
  }

  # Add more zones as needed:
  # "zone://team1/infra_zone2" = {
  #   subnet_fqrn  = "sub://team1/infra/demo_vcn/subnet2"
  #   bastion_fqrn = "bastion://team1/infra/demo_bastion"
  #   ad           = 1
  # }
}
