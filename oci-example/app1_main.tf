# ═══════════════════════════════════════════════════════════════
# APP1 Infrastructure
# APP1-specific NSGs and Compute Instances
# ═══════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════
# APP1 Network Security Groups (depends on subnets)
# ═══════════════════════════════════════════════════════════════

module "app1_nsgs" {
  source   = "./modules/nsg"
  for_each = var.app1_nsgs

  nsg_fqrn = each.key # NSG FQRN is the map key (e.g., "nsg://vm_demo/demo/demo_vcn/ssh")
  fqrn_map = local.compartment_vcn_subnet_fqrns # Pass compartment + VCN + Subnet FQRNs (excludes NSGs to avoid cycle)
  rules    = each.value.rules

  depends_on = [module.subnets]
}

# ═══════════════════════════════════════════════════════════════
# APP1 Compute Instances (depends on all network resources)
# ═══════════════════════════════════════════════════════════════

module "app1_compute_instances" {
  source   = "./modules/compute_instance"
  for_each = var.app1_compute_instances

  instance_fqrn          = each.key # Instance FQRN is the map key (e.g., "instance://vm_demo/demo/demo_instance")
  zone                    = {
    subnet = var.zones[each.value.zone].subnet
    ad     = var.zones[each.value.zone].ad
  }
  nsg                     = each.value.nsg # NSG as co-resource, not part of zone
  spec                    = each.value.spec
  fqrn_map                = local.network_fqrns # Includes VCN, subnet, all NSGs (app1 + app2)
  availability_domain_name = data.oci_identity_availability_domains.ads.availability_domains[var.zones[each.value.zone].ad].name

  depends_on = [module.subnets]
}

