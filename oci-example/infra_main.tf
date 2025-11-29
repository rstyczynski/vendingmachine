# ═══════════════════════════════════════════════════════════════
# Infrastructure
# Compartments, VCNs, and Subnets - shared by all applications
# ═══════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════
# LAYER 1: Compartments
# ═══════════════════════════════════════════════════════════════

module "compartments" {
  source = "./modules/compartments"

  tenancy_ocid = local.tenancy_ocid
  compartments = var.compartments
}

# ═══════════════════════════════════════════════════════════════
# LAYER 2: VCNs (depends on compartments)
# ═══════════════════════════════════════════════════════════════

module "vcns" {
  source   = "./modules/vcn"
  for_each = var.vcns

  vcn_fqrn             = each.key # VCN FQRN is the map key (e.g., "vcn://vm_demo/demo/demo_vcn")
  fqrn_map             = local.compartment_fqrns # Pass compartment FQRNs
  cidr_blocks          = each.value.cidr_blocks
  dns_label            = each.value.dns_label
  create_internet_gateway = each.value.create_internet_gateway

  depends_on = [module.compartments]
}

# ═══════════════════════════════════════════════════════════════
# LAYER 3: Subnets (depends on compartments + VCNs)
# ═══════════════════════════════════════════════════════════════

module "subnets" {
  source   = "./modules/subnet"
  for_each = var.subnets

  subnet_fqrn             = each.key # Subnet FQRN is the map key (e.g., "sub://vm_demo/demo/demo_vcn/public_subnet")
  fqrn_map               = local.compartment_and_vcn_fqrns # Pass compartment + VCN FQRNs
  cidr_block             = each.value.cidr_block
  dns_label              = each.value.dns_label
  prohibit_public_ip_on_vnic = each.value.prohibit_public_ip_on_vnic

  depends_on = [module.vcns]
}

