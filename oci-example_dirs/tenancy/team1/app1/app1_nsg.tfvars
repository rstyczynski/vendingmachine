app1_nsgs = {
  "nsg://team1/app1/demo_vcn/ssh" = {
    rules = {
      ssh_ingress = {
        direction   = "INGRESS"
        protocol    = "6" # TCP
        source      = "0.0.0.0/0"
        source_type = "CIDR_BLOCK"
        description = "Allow SSH from anywhere"
        tcp_options = {
          destination_port_min = 22
          destination_port_max = 22
        }
      }

      all_egress = {
        direction        = "EGRESS"
        protocol         = "all"
        destination      = "0.0.0.0/0"
        destination_type = "CIDR_BLOCK"
        description      = "Allow all egress traffic"
      }
    }
  }
}
