# ═══════════════════════════════════════════════════════════════
# INFRA Zone Configuration
# Logical groupings of subnet, availability domain, and bastion
#
# OWNERSHIP: Zone does NOT create subnets or bastions.
#            These resources must exist in advance.
# ═══════════════════════════════════════════════════════════════

infra_zones = {
  "zone://vm_demo/demo/infra" = {
    subnet_fqrn  = "sub://vm_demo/demo/demo_vcn/subnet"     # Subnet FQRN
    bastion_fqrn = "bastion://vm_demo/demo/demo_bastion"    # Bastion FQRN (optional)
    ad           = 0                                         # Availability domain: 0, 1, or 2
  }

  # Add more zones as needed:
  # "zone://vm_demo/demo/infra_zone2" = {
  #   subnet_fqrn  = "sub://vm_demo/demo/demo_vcn/subnet2"
  #   bastion_fqrn = "bastion://vm_demo/demo/demo_bastion"
  #   ad           = 1
  # }
}
