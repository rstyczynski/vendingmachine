# ═══════════════════════════════════════════════════════════════
# APP1 Infrastructure
# Shares VCN, Subnet, and Compartment with main infrastructure
# ═══════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════
# APP1 Network Security Groups
# ═══════════════════════════════════════════════════════════════

module "app1_nsgs" {
  source   = "./modules/nsg"
  for_each = var.app1_nsgs

  nsg_fqrn = each.key # NSG FQRN is the map key (e.g., "nsg://vm_demo/demo/demo_vcn/ssh")
  fqrn_map = local.network_fqrns_base # Pass base network FQRNs (VCN, subnet - excludes app NSGs to avoid cycle)
  rules    = each.value.rules

  depends_on = [module.subnets]
}

# ═══════════════════════════════════════════════════════════════
# APP1 Compute Instances
# ═══════════════════════════════════════════════════════════════

module "app1_compute_instances" {
  source   = "./modules/compute_instance"
  for_each = var.app1_compute_instances

  instance_fqrn = each.key # Instance FQRN is the map key (e.g., "instance://vm_demo/demo/demo_instance")
  zone = {
    subnet = var.zones[each.value.zone].subnet
    ad     = var.zones[each.value.zone].ad
  }
  nsg                     = each.value.nsg # NSG as co-resource
  spec                    = each.value.spec
  fqrn_map                = local.network_fqrns  # Includes VCN, subnet, main NSGs, and APP2 NSGs (from fqrn.tf)
  availability_domain_name = data.oci_identity_availability_domains.ads.availability_domains[var.zones[each.value.zone].ad].name

  depends_on = [
    module.subnets,
    module.app1_nsgs
  ]
}

