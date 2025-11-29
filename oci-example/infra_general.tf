# ═══════════════════════════════════════════════════════════════
# Infrastructure Locals
# Tenancy, region, and availability domains - used by all applications
# ═══════════════════════════════════════════════════════════════

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
