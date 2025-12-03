output "id" {
  description = "Instance OCID"
  value       = oci_core_instance.this.id
}

output "name" {
  description = "Instance display name"
  value       = oci_core_instance.this.display_name
}

output "public_ip" {
  description = "Instance public IP"
  value       = oci_core_instance.this.public_ip
}

output "private_ip" {
  description = "Instance private IP"
  value       = oci_core_instance.this.private_ip
}

output "state" {
  description = "Instance state"
  value       = oci_core_instance.this.state
}

output "fqrn_map" {
  description = "FQRN → OCID mapping for this compute instance"
  value = {
    "instance://${local.compartment_path}/${oci_core_instance.this.display_name}" = oci_core_instance.this.id
  }
}
