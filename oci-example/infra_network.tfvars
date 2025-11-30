vcns = {
  "vcn://vm_demo/demo/demo_vcn" = {
    cidr_blocks             = ["10.0.0.0/16"]
    dns_label               = "demovcn"
    create_internet_gateway = false
    create_nat_gateway      = true
    create_service_gateway  = true  # Enable service gateway for OCI services access
    service_gateway_services = []   # Empty list = all services
  }
}

# Subnets Map
subnets = {
  "sub://vm_demo/demo/demo_vcn/subnet" = {
    cidr_block                 = "10.0.1.0/24"
    dns_label                  = "publicsubnet"
    prohibit_public_ip_on_vnic = true
    enable_flow_log            = true
    flow_log_log_group_fqrn    = "log_group://vm_demo/demo/demo_log_group"
  }
}


