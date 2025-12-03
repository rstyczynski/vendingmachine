# ═══════════════════════════════════════════════════════════════
# APP2 Network Security Groups Configuration
# ═══════════════════════════════════════════════════════════════

app2_nsgs = {
  "nsg://vm_ABC/999/db_nsg" = {
    rules = {
      all_egress = {
        direction        = "EGRESS"
        protocol         = "all"
        destination      = "0.0.0.0/0"
        destination_type = "CIDR_BLOCK"
        description      = "Allow all egress traffic"
      }
      db_ingress = {
        direction        = "INGRESS"
        protocol         = "6"
        source           = "10.0.0.0/16"
        source_type      = "CIDR_BLOCK"
        description      = "Allow database access from VCN"
        tcp_options = {
          destination_port_min = 1521
          destination_port_max = 1521
        }
      }
    }
  }

  "nsg://vm_ABC/999/web_nsg" = {
    rules = {
      all_egress = {
        direction        = "EGRESS"
        protocol         = "all"
        destination      = "0.0.0.0/0"
        destination_type = "CIDR_BLOCK"
        description      = "Allow all egress traffic"
      }
      http_ingress = {
        direction        = "INGRESS"
        protocol         = "6"
        source           = "0.0.0.0/0"
        source_type      = "CIDR_BLOCK"
        description      = "Allow HTTP from anywhere"
        tcp_options = {
          destination_port_min = 80
          destination_port_max = 80
        }
      }
      https_ingress = {
        direction        = "INGRESS"
        protocol         = "6"
        source           = "0.0.0.0/0"
        source_type      = "CIDR_BLOCK"
        description      = "Allow HTTPS from anywhere"
        tcp_options = {
          destination_port_min = 443
          destination_port_max = 443
        }
      }
    }
  }

}

