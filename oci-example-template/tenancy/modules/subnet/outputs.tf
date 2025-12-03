output "id" {
  description = "Subnet OCID"
  value       = oci_core_subnet.this.id
}

output "name" {
  description = "Subnet display name"
  value       = oci_core_subnet.this.display_name
}

output "fqrn_map" {
  description = "FQRN → OCID mapping for this subnet"
  value = {
    "sub://${local.compartment_path}/${local.vcn_name}/${oci_core_subnet.this.display_name}" = oci_core_subnet.this.id
  }
}

output "flow_log_id" {
  description = "Flow log OCID (if enabled)"
  value       = var.enable_flow_log ? oci_logging_log.this[0].id : null
}
