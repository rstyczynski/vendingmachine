
locals {
  # Resolve tenancy and region from FQRNs
  tenancy_ocid = var.tenancies[var.tenancy].tenancy_ocid
  
  # Parse region FQRN: region://realm/region_name
  region_fqrn_parts = regex("^region://[^/]+/(.+)$", var.region)
  region_name       = local.region_fqrn_parts[0]  # Extract region name from FQRN
}

# Get availability domains (shared by all applications)
data "oci_identity_availability_domains" "ads" {
  compartment_id = local.tenancy_ocid
}

variable "tenancies" {
  description = "Map of tenancies, indexed by tenancy FQRN (e.g., tenancy://oc1/avq3)"
  type = map(object({
    description   = string
    tenancy_ocid  = string
  }))
  default = {}
}

variable "tenancy" {
  description = "Tenancy FQRN to use (must exist in tenancies map)"
  type        = string
}

variable "regions" {
  description = "Map of regions, indexed by region FQRN (e.g., region://oc1/eu-zurich-1)"
  type = map(object({
    description = string
  }))
  default = {}
}

variable "region" {
  description = "Region FQRN to use (must exist in regions map)"
  type        = string
}





