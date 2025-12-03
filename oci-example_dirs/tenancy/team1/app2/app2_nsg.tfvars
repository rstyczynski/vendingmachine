app2_nsgs = {
  "nsg://team1/app2/demo_vcn/app2_web" = {
    rules = {
      http_ingress = {
        direction   = "INGRESS"
        protocol    = "6" # TCP
        source      = "0.0.0.0/0"
        source_type = "CIDR_BLOCK"
        description = "Allow HTTP from anywhere"
        tcp_options = {
          destination_port_min = 80
          destination_port_max = 80
        }
      }
      https_ingress = {
        direction   = "INGRESS"
        protocol    = "6" # TCP
        source      = "0.0.0.0/0"
        source_type = "CIDR_BLOCK"
        description = "Allow HTTPS from anywhere"
        tcp_options = {
          destination_port_min = 443
          destination_port_max = 443
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
