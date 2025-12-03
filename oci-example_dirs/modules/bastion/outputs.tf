output "id" {
  description = "Bastion OCID"
  value       = oci_bastion_bastion.this.id
}

output "name" {
  description = "Bastion display name"
  value       = oci_bastion_bastion.this.name
}

output "state" {
  description = "Bastion state"
  value       = oci_bastion_bastion.this.state
}

output "fqrn_map" {
  description = "FQRN → OCID mapping for this bastion"
  value = {
    "${var.bastion_fqrn}" = oci_bastion_bastion.this.id
  }
}

