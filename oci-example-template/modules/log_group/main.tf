# Parse log group FQRN and derive compartment_ocid
locals {
  # Parse log group FQRN: log_group://compartment_path/log_group_name
  # Example: "log_group://vm_demo/demo/demo_log_group" -> path is "vm_demo/demo", name is "demo_log_group"
  log_group_fqrn_parts = regex("^log_group://(.+)/([^/]+)$", var.log_group_fqrn)
  compartment_path    = local.log_group_fqrn_parts[0]  # Extract compartment path from log group FQRN (e.g., "vm_demo/demo")
  log_group_name      = local.log_group_fqrn_parts[1]  # Extract log group name from log group FQRN

  # Derive compartment FQRN from log group FQRN (following FQRN scheme rules)
  # Compartment FQRN format: cmp:///compartment_path (with leading slash to match compartment module output)
  compartment_fqrn = "cmp:///${local.compartment_path}"

  # Resolve compartment FQRN to OCID
  compartment_id = var.fqrn_map[local.compartment_fqrn]
}

resource "oci_logging_log_group" "this" {
  compartment_id = local.compartment_id
  display_name   = local.log_group_name  # Use log group name extracted from FQRN
  description    = var.description

  freeform_tags = {
    "managed_by" = "terraform"
    "component"  = "oci-vending-machine"
  }
}

