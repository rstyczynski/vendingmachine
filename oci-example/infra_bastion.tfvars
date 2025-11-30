bastions = {
  "bastion://vm_demo/demo/demo_bastion" = {
    target_subnet_fqrn            = "sub://vm_demo/demo/demo_vcn/public_subnet" # Subnet FQRN that bastion connects to
    bastion_type                   = "STANDARD"                                  # Type of bastion
    client_cidr_block_allow_list   = ["0.0.0.0/0"]                                          # Empty list allows all (or specify CIDR blocks)
    max_session_ttl_in_seconds     = 10800                                       # 3 hours
    dns_proxy_status               = "DISABLED"                                   # DNS proxy status
  }
}

