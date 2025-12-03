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
  count = var.create_internet_gateway || var.create_service_gateway || var.create_nat_gateway ? 1 : 0

  manage_default_resource_id = oci_core_vcn.this.default_route_table_id
  display_name               = "${local.vcn_name}-default-rt"

  # Add internet gateway route if internet gateway is enabled
  # Note: IGW and SGW "All Services" cannot be in the same route table (OCI limitation)
  # When IGW is enabled, SGW routes go to a separate route table
  dynamic "route_rules" {
    for_each = var.create_internet_gateway ? [1] : []
    content {
      network_entity_id = oci_core_internet_gateway.this[0].id
      destination       = "0.0.0.0/0"
      destination_type  = "CIDR_BLOCK"
    }
  }

  # Add NAT gateway route if NAT gateway is enabled and IGW is NOT enabled
  # (When IGW is enabled, NAT goes to SGW route table if SGW is enabled)
  # NAT can coexist with Service Gateway in the same route table
  dynamic "route_rules" {
    for_each = var.create_nat_gateway && !var.create_internet_gateway ? [1] : []
    content {
      destination       = "0.0.0.0/0"
      destination_type  = "CIDR_BLOCK"
      network_entity_id = oci_core_nat_gateway.this[0].id
    }
  }

  # Add service gateway route if service gateway is enabled and IGW is NOT enabled
  # (When IGW is enabled, SGW goes to a separate route table)
  # SGW can coexist with NAT gateway in the same route table
  dynamic "route_rules" {
    for_each = var.create_service_gateway && !var.create_internet_gateway ? [1] : []
    content {
      destination       = data.oci_core_services.all_services[0].services[0].cidr_block
      destination_type  = "SERVICE_CIDR_BLOCK"
      network_entity_id = oci_core_service_gateway.this[0].id
    }
  }

  freeform_tags = {
    "managed_by" = "terraform"
    "component"  = "oci-vending-machine"
  }
}

# Get all OCI services for service gateway
data "oci_core_services" "all_services" {
  count = var.create_service_gateway ? 1 : 0
  filter {
    name   = "name"
    values = length(var.service_gateway_services) > 0 ? var.service_gateway_services : ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

resource "oci_core_service_gateway" "this" {
  count = var.create_service_gateway ? 1 : 0

  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${local.vcn_name}-sgw"

  services {
    service_id = data.oci_core_services.all_services[0].services[0].id
  }

  freeform_tags = {
    "managed_by" = "terraform"
    "component"  = "oci-vending-machine"
  }
}

# Service Gateway Route Table (for private subnets to access OCI services)
# This route table combines Service Gateway + NAT Gateway routes
# Used when IGW is enabled (since IGW and SGW "All Services" cannot be in the same route table per OCI limitation)
# When IGW is NOT enabled, SGW and NAT routes go to the default route table
resource "oci_core_route_table" "service_gateway_rt" {
  count = var.create_service_gateway && var.create_internet_gateway ? 1 : 0

  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${local.vcn_name}-sgw-rt"

  # Service Gateway route for OCI services
  route_rules {
    destination       = data.oci_core_services.all_services[0].services[0].cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.this[0].id
  }

  # NAT Gateway route for internet access (if NAT gateway is enabled)
  # NAT and SGW can coexist in the same route table
  dynamic "route_rules" {
    for_each = var.create_nat_gateway ? [1] : []
    content {
      destination       = "0.0.0.0/0"
      destination_type  = "CIDR_BLOCK"
      network_entity_id = oci_core_nat_gateway.this[0].id
    }
  }

  freeform_tags = {
    "managed_by" = "terraform"
    "component"  = "oci-vending-machine"
  }
}

# NAT Gateway (for private subnets to access internet)
resource "oci_core_nat_gateway" "this" {
  count = var.create_nat_gateway ? 1 : 0

  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${local.vcn_name}-nat"

  freeform_tags = {
    "managed_by" = "terraform"
    "component"  = "oci-vending-machine"
  }
}

# NAT Gateway Route Table (for private subnets to access internet)
# This route table is only used when NAT is enabled but IGW and SGW are NOT enabled
# When IGW is NOT enabled, NAT and SGW routes go to the default route table
# This separate RT is only needed if you want NAT-only routing (without SGW)
resource "oci_core_route_table" "nat_gateway_rt" {
  count = var.create_nat_gateway && !var.create_internet_gateway && !var.create_service_gateway ? 1 : 0

  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${local.vcn_name}-nat-rt"

  # NAT Gateway route for internet access
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.this[0].id
  }

  freeform_tags = {
    "managed_by" = "terraform"
    "component"  = "oci-vending-machine"
  }
}
