# Parse NSG FQRN and derive compartment_ocid and vcn_ocid
locals {
  # Parse NSG FQRN: nsg://compartment_path/vcn_name/nsg_name
  nsg_fqrn_parts   = regex("^nsg://(.+)/([^/]+)/([^/]+)$", var.nsg_fqrn)
  compartment_path = local.nsg_fqrn_parts[0]  # Extract compartment path from NSG FQRN (e.g., "vm_demo/demo")
  vcn_name         = local.nsg_fqrn_parts[1]  # Extract VCN name from NSG FQRN
  nsg_name         = local.nsg_fqrn_parts[2]  # Extract NSG name from NSG FQRN

  # Derive compartment and VCN FQRNs from NSG FQRN (following FQRN scheme rules)
  # Compartment FQRN format: cmp:///compartment_path (with leading slash to match compartment module output)
  # VCN FQRN format: vcn://compartment_path/vcn_name (matches VCN module output format)
  # The compartment_path from NSG FQRN is like "vm_demo/demo"
  compartment_fqrn = "cmp:///${local.compartment_path}"
  vcn_fqrn         = "vcn://${local.compartment_path}/${local.vcn_name}"

  # Resolve FQRNs to OCIDs
  compartment_id = var.fqrn_map[local.compartment_fqrn]
  vcn_id         = var.fqrn_map[local.vcn_fqrn]
}

resource "oci_core_network_security_group" "this" {
  compartment_id = local.compartment_id
  vcn_id         = local.vcn_id
  display_name   = local.nsg_name  # Use NSG name extracted from FQRN

  freeform_tags = {
    "managed_by" = "terraform"
    "component"  = "oci-vending-machine"
  }
}

resource "oci_core_network_security_group_security_rule" "this" {
  for_each = var.rules

  network_security_group_id = oci_core_network_security_group.this.id
  direction                 = each.value.direction
  protocol                  = each.value.protocol

  # Source/Destination based on direction
  source           = each.value.direction == "INGRESS" ? each.value.source : null
  source_type      = each.value.direction == "INGRESS" ? each.value.source_type : null
  destination      = each.value.direction == "EGRESS" ? each.value.destination : null
  destination_type = each.value.direction == "EGRESS" ? each.value.destination_type : null

  description = each.value.description

  # TCP options
  dynamic "tcp_options" {
    for_each = each.value.tcp_options != null ? [each.value.tcp_options] : []
    content {
      dynamic "destination_port_range" {
        for_each = tcp_options.value.destination_port_min != null ? [1] : []
        content {
          min = tcp_options.value.destination_port_min
          max = tcp_options.value.destination_port_max
        }
      }
      dynamic "source_port_range" {
        for_each = tcp_options.value.source_port_min != null ? [1] : []
        content {
          min = tcp_options.value.source_port_min
          max = tcp_options.value.source_port_max
        }
      }
    }
  }

  # UDP options
  dynamic "udp_options" {
    for_each = each.value.udp_options != null ? [each.value.udp_options] : []
    content {
      dynamic "destination_port_range" {
        for_each = udp_options.value.destination_port_min != null ? [1] : []
        content {
          min = udp_options.value.destination_port_min
          max = udp_options.value.destination_port_max
        }
      }
      dynamic "source_port_range" {
        for_each = udp_options.value.source_port_min != null ? [1] : []
        content {
          min = udp_options.value.source_port_min
          max = udp_options.value.source_port_max
        }
      }
    }
  }

  # ICMP options
  dynamic "icmp_options" {
    for_each = each.value.icmp_options != null ? [each.value.icmp_options] : []
    content {
      type = icmp_options.value.type
      code = icmp_options.value.code
    }
  }
}
