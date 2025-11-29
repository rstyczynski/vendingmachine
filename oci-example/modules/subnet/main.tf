# Parse subnet FQRN and derive compartment_ocid and vcn_ocid
locals {
  # Parse subnet FQRN: sub://compartment_path/vcn_name/subnet_name
  subnet_fqrn_parts = regex("^sub://(.+)/([^/]+)/([^/]+)$", var.subnet_fqrn)
  compartment_path  = local.subnet_fqrn_parts[0]  # Extract compartment path from subnet FQRN (e.g., "vm_demo/demo")
  vcn_name          = local.subnet_fqrn_parts[1]  # Extract VCN name from subnet FQRN
  subnet_name       = local.subnet_fqrn_parts[2]  # Extract subnet name from subnet FQRN

  # Derive compartment and VCN FQRNs from subnet FQRN (following FQRN scheme rules)
  # Compartment FQRN format: cmp:///compartment_path (with leading slash to match compartment module output)
  # VCN FQRN format: vcn://compartment_path/vcn_name (matches VCN module output format)
  compartment_fqrn = "cmp:///${local.compartment_path}"
  vcn_fqrn         = "vcn://${local.compartment_path}/${local.vcn_name}"

  # Resolve FQRNs to OCIDs
  compartment_id = var.fqrn_map[local.compartment_fqrn]
  vcn_id         = var.fqrn_map[local.vcn_fqrn]
}

resource "oci_core_subnet" "this" {
  compartment_id             = local.compartment_id
  vcn_id                     = local.vcn_id
  display_name               = local.subnet_name  # Use subnet name extracted from FQRN
  cidr_block                 = var.cidr_block
  dns_label                  = var.dns_label
  prohibit_public_ip_on_vnic = var.prohibit_public_ip_on_vnic

  freeform_tags = {
    "managed_by" = "terraform"
    "component"  = "oci-vending-machine"
  }
}
