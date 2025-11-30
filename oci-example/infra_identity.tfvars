# Compartments Map
compartments = {
  "cmp:///vm_demo/demo" = {
    description   = "Demo Compartment"
    enable_delete = false
  }
}

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

