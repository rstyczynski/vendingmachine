# ═══════════════════════════════════════════════════════════════
# APP1 Network Security Groups Configuration
# ═══════════════════════════════════════════════════════════════

app1_nsgs = {
  "nsg://vm_XXX/ABC/ssh" = {
    rules = {
      all_egress = {
        direction        = "EGRESS"
        protocol         = "all"
        destination      = "0.0.0.0/0"
        destination_type = "CIDR_BLOCK"
        description      = "Allow all egress traffic"
      }
      ssh_ingress = {
        direction        = "INGRESS"
        protocol         = "6"
        source           = "0.0.0.0/0"
        source_type      = "CIDR_BLOCK"
        description      = "Allow SSH from anywhere"
        tcp_options = {
          destination_port_min = 22
          destination_port_max = 22
        }
      }
    }
  }

}

