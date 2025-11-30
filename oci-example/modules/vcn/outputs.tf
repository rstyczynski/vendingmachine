output "id" {
  description = "VCN OCID"
  value       = oci_core_vcn.this.id
}

output "name" {
  description = "VCN display name"
  value       = oci_core_vcn.this.display_name
}

output "default_route_table_id" {
  description = "Default route table OCID"
  value       = oci_core_vcn.this.default_route_table_id
}

output "default_security_list_id" {
  description = "Default security list OCID"
  value       = oci_core_vcn.this.default_security_list_id
}

output "internet_gateway_id" {
  description = "Internet gateway OCID"
  value       = var.create_internet_gateway ? oci_core_internet_gateway.this[0].id : null
}

output "service_gateway_id" {
  description = "Service gateway OCID"
  value       = var.create_service_gateway ? oci_core_service_gateway.this[0].id : null
}

output "service_gateway_route_table_id" {
  description = "Service gateway route table OCID (for private subnets). Only created when IGW is enabled (since IGW and SGW cannot be in same RT). When IGW is NOT enabled, SGW routes are in default RT."
  value       = var.create_service_gateway && var.create_internet_gateway ? oci_core_route_table.service_gateway_rt[0].id : null
}

output "nat_gateway_id" {
  description = "NAT gateway OCID"
  value       = var.create_nat_gateway ? oci_core_nat_gateway.this[0].id : null
}

output "nat_gateway_route_table_id" {
  description = "NAT gateway route table OCID (for private subnets to access internet). Only created when NAT is enabled but IGW and SGW are NOT enabled. When IGW is NOT enabled, NAT and SGW routes are in default RT."
  value       = var.create_nat_gateway && !var.create_internet_gateway && !var.create_service_gateway ? oci_core_route_table.nat_gateway_rt[0].id : null
}

output "fqrn_map" {
  description = "FQRN → OCID mapping for this VCN"
  value = {
    "vcn://${local.compartment_path}/${oci_core_vcn.this.display_name}" = oci_core_vcn.this.id
  }
}
