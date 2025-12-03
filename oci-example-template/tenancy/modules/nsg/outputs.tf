output "id" {
  description = "NSG OCID"
  value       = oci_core_network_security_group.this.id
}

output "name" {
  description = "NSG display name"
  value       = oci_core_network_security_group.this.display_name
}

output "rules" {
  description = "NSG rule details"
  value = {
    for k, r in oci_core_network_security_group_security_rule.this : k => {
      id          = r.id
      direction   = r.direction
      protocol    = r.protocol
      description = r.description
    }
  }
}

output "fqrn_map" {
  description = "FQRN → OCID mapping for this NSG"
  value = {
    "nsg://${local.compartment_path}/${local.vcn_name}/${oci_core_network_security_group.this.display_name}" = oci_core_network_security_group.this.id
  }
}
