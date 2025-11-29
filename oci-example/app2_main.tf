# ═══════════════════════════════════════════════════════════════
# APP2 Infrastructure
# Shares VCN, Subnet, and Compartment with main infrastructure
# ═══════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════
# APP2 Network Security Groups
# ═══════════════════════════════════════════════════════════════

module "app2_nsgs" {
  source   = "./modules/nsg"
  for_each = var.app2_nsgs

  nsg_fqrn = each.key # NSG FQRN is the map key (e.g., "nsg://vm_demo/demo/demo_vcn/app2_web")
  fqrn_map = local.network_fqrns_base # Pass base network FQRNs (VCN, subnet - excludes app NSGs to avoid cycle)
  rules    = each.value.rules

  depends_on = [module.subnets]
}

# ═══════════════════════════════════════════════════════════════
# APP2 Compute Instances
# ═══════════════════════════════════════════════════════════════

module "app2_compute_instances" {
  source   = "./modules/compute_instance"
  for_each = var.app2_compute_instances

  instance_fqrn = each.key # Instance FQRN is the map key (e.g., "instance://vm_demo/demo/app2_instance")
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
    module.app2_nsgs
  ]
}

