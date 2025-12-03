# Parse compartment FQRN to extract compartment name
locals {
  # Parse compartment FQRN: cmp://compartment_path or cmp:///compartment_path
  # Example: "cmp://vm_demo/demo" -> path is "vm_demo/demo", name is "demo" (last segment)
  # Example: "cmp:///vm_demo/demo" -> path is "vm_demo/demo", name is "demo" (last segment)
  compartment_fqrn_parts = regex("^cmp:///*(.+)$", var.name)
  compartment_path       = local.compartment_fqrn_parts[0]
  
  # Extract the last segment as the compartment name
  # Split by "/" and take the last element
  path_segments = split("/", local.compartment_path)
  compartment_name = local.path_segments[length(local.path_segments) - 1]
}

resource "oci_identity_compartment" "this" {
  compartment_id = var.parent_compartment_id
  name           = local.compartment_name  # Use only the last segment as the compartment name
  description    = var.description
  enable_delete  = var.enable_delete

  freeform_tags = {
    "managed_by" = "terraform"
    "component"  = "oci-vending-machine"
  }
}
