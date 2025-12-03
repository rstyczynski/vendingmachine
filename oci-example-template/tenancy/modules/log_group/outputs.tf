output "id" {
  description = "Log group OCID"
  value       = oci_logging_log_group.this.id
}

output "name" {
  description = "Log group display name"
  value       = oci_logging_log_group.this.display_name
}

output "fqrn_map" {
  description = "FQRN → OCID mapping for this log group"
  value = {
    "log_group://${local.compartment_path}/${oci_logging_log_group.this.display_name}" = oci_logging_log_group.this.id
  }
}

