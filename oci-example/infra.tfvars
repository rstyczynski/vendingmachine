# ═══════════════════════════════════════════════════════════════
# Infrastructure Configuration
# Tenancy, region, compartments, VCNs, subnets - shared by all applications
# ═══════════════════════════════════════════════════════════════

# Tenancies Map
tenancies = {
  "tenancy://oc1/avg3" = {
    description  = "VM Demo Tenancy"
    tenancy_ocid = "ocid1.tenancy.oc1..aaaaaaaay2b2tvqcmqmndvcbz5kuptzuo7sp4vufarqfgoru7qojdgywb27a" # Replace with your actual tenancy OCID
  }
}

# Selected Tenancy
tenancy = "tenancy://oc1/avg3"

# Regions Map
regions = {
  "region://oc1/eu-zurich-1" = {
    description = "Zurich Region"
  }
}

# Selected Region
region = "region://oc1/eu-zurich-1"

# Compartments Map
compartments = {
  "cmp:///vm_demo/demo" = {
    description   = "Demo Compartment"
    enable_delete = false
  }
}

# VCNs Map
vcns = {
  "vcn://vm_demo/demo/demo_vcn" = {
    cidr_blocks             = ["10.0.0.0/16"]
    dns_label               = "demovcn"
    create_internet_gateway = true
  }
}

# Subnets Map
subnets = {
  "sub://vm_demo/demo/demo_vcn/public_subnet" = {
    cidr_block                 = "10.0.1.0/24"
    dns_label                  = "publicsubnet"
    prohibit_public_ip_on_vnic = false
  }
}

# Shared Zones (Location Contexts)
zones = {
  "zone://vm_demo/demo/app" = {
    #compartment = "cmp://vm_demo/demo"                         # FQRN
    subnet      = "sub://vm_demo/demo/demo_vcn/public_subnet"   # FQRN
    ad          = 0                                             # Availability domain
  }
  "zone://vm_demo/demo/app2" = {
    #compartment = "cmp://vm_demo/demo"                         # FQRN
    subnet      = "sub://vm_demo/demo/demo_vcn/public_subnet"   # FQRN
    ad          = 0                                             # Availability domain
  }
}

