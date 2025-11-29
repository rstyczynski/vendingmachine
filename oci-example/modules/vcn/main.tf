# Parse VCN FQRN and derive compartment_ocid
locals {
  # Parse VCN FQRN: vcn://compartment_path/vcn_name
  vcn_fqrn_parts   = regex("^vcn://(.+)/([^/]+)$", var.vcn_fqrn)
  compartment_path = local.vcn_fqrn_parts[0]  # Extract compartment path from VCN FQRN (e.g., "demo")
  vcn_name         = local.vcn_fqrn_parts[1]  # Extract VCN name from VCN FQRN

  # Derive compartment FQRN from VCN FQRN (following FQRN scheme rules)
  # Compartment FQRN format: cmp:///compartment_path (with leading slash to match compartment module output)
  # The compartment_path from VCN FQRN is like "vm_demo/demo", we need "cmp:///vm_demo/demo"
  compartment_fqrn = "cmp:///${local.compartment_path}"

  # Resolve compartment FQRN to OCID
  compartment_id = var.fqrn_map[local.compartment_fqrn]
}

resource "oci_core_vcn" "this" {
  compartment_id = local.compartment_id
  display_name   = local.vcn_name  # Use VCN name extracted from FQRN
  cidr_blocks    = var.cidr_blocks
  dns_label      = var.dns_label

  freeform_tags = {
    "managed_by" = "terraform"
    "component"  = "oci-vending-machine"
  }
}

resource "oci_core_internet_gateway" "this" {
  count = var.create_internet_gateway ? 1 : 0

  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${local.vcn_name}-igw"
  enabled        = true

  freeform_tags = {
    "managed_by" = "terraform"
    "component"  = "oci-vending-machine"
  }
}

resource "oci_core_default_route_table" "this" {
  count = var.create_internet_gateway ? 1 : 0

  manage_default_resource_id = oci_core_vcn.this.default_route_table_id
  display_name               = "${local.vcn_name}-default-rt"

  route_rules {
    network_entity_id = oci_core_internet_gateway.this[0].id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }

  freeform_tags = {
    "managed_by" = "terraform"
    "component"  = "oci-vending-machine"
  }
}
