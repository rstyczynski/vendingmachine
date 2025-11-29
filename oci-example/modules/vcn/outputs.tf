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

output "fqrn_map" {
  description = "FQRN → OCID mapping for this VCN"
  value = {
    "vcn://${local.compartment_path}/${oci_core_vcn.this.display_name}" = oci_core_vcn.this.id
  }
}
