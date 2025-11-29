# Parse instance FQRN and derive compartment_ocid
locals {
  # Parse instance FQRN: instance://compartment_path/instance_name
  instance_fqrn_parts = regex("^instance://(.+)/([^/]+)$", var.instance_fqrn)
  compartment_path    = local.instance_fqrn_parts[0]  # Extract compartment path from instance FQRN (e.g., "vm_demo/demo")
  instance_name        = local.instance_fqrn_parts[1]  # Extract instance name from instance FQRN

  # Derive compartment FQRN from instance FQRN (following FQRN scheme rules)
  # Compartment FQRN format: cmp:///compartment_path (with leading slash to match compartment module output)
  compartment_fqrn = "cmp:///${local.compartment_path}"

  # Resolve FQRNs to OCIDs
  compartment_id = var.fqrn_map[local.compartment_fqrn]
  subnet_id      = var.fqrn_map[var.zone.subnet]
  nsg_ids        = [for nsg_fqrn in var.nsg : var.fqrn_map[nsg_fqrn]]
}

# Get latest Oracle Linux 8 image if not provided
data "oci_core_images" "ol8" {
  count = var.spec.source_image_id == null ? 1 : 0

  compartment_id           = local.compartment_id
  operating_system         = "Oracle Linux"
  operating_system_version = "8"
  shape                    = var.spec.shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

resource "oci_core_instance" "this" {
  compartment_id      = local.compartment_id
  availability_domain = var.availability_domain_name
  display_name        = local.instance_name  # Use instance name extracted from FQRN
  shape               = var.spec.shape

  shape_config {
    ocpus         = var.spec.ocpus
    memory_in_gbs = var.spec.memory_in_gbs
  }

  create_vnic_details {
    subnet_id        = local.subnet_id
    assign_public_ip = var.spec.assign_public_ip
    nsg_ids          = local.nsg_ids
    display_name     = "${local.instance_name}-vnic"
  }

  source_details {
    source_type             = "image"
    source_id               = var.spec.source_image_id != null ? var.spec.source_image_id : data.oci_core_images.ol8[0].images[0].id
    boot_volume_size_in_gbs = var.spec.boot_volume_size_in_gbs
  }

  metadata = {
    ssh_authorized_keys = var.spec.ssh_public_key
  }

  freeform_tags = {
    "managed_by" = "terraform"
    "component"  = "oci-vending-machine"
  }
}
