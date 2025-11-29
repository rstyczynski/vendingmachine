output "id" {
  description = "Compartment OCID"
  value       = oci_identity_compartment.this.id
}

output "name" {
  description = "Compartment name"
  value       = oci_identity_compartment.this.name
}

output "fqrn_map" {
  description = "FQRN → OCID mapping for this compartment"
  value = {
    "cmp:///${local.compartment_path}" = oci_identity_compartment.this.id  # Use leading slash to match format used by other modules
  }
}
