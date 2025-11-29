# ═══════════════════════════════════════════════════════════════
# APP2 Network Security Groups (NSGs)
# ═══════════════════════════════════════════════════════════════

app2_nsgs = {
  "nsg://vm_demo/demo/demo_vcn/app2_web" = {
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

# ═══════════════════════════════════════════════════════════════
# APP2 Compute Instances
# ═══════════════════════════════════════════════════════════════

app2_compute_instances = {
  "instance://vm_demo/demo/app2_instance" = {
    zone = "zone://vm_demo/demo/app2" # Zone map key reference (for AD only)
    
    nsg  = ["nsg://vm_demo/demo/demo_vcn/app2_web"] # APP2 NSG FQRN list

    spec = {
      shape                   = "VM.Standard.E4.Flex"
      ocpus                   = 1
      memory_in_gbs           = 16
      assign_public_ip        = true
      ssh_public_key          = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDi7dWcWn0+ciNUI35ItsmchDxEV8+HyRmVvGVo1I9gbDI7Y+k4KkW1fdls1YfgzuLdah61SLvlnSRjG6D33EmaKL6l9GjzLIFNDPR9InTT2iPBGzm/bVy6jXYBT5+r4Yriw3ggxeudu6vkSxjBzXch3Dgkj58xcHt9qRbVPp9iEnBbBvBEHEuJ+Gnx4xBDhXS/ZXANwAAfgO/Y0SNSzjsOoFCG8diBJ3gT6fyIVrMxVHFk7n21k7Ef4SaYv6uV8xy2rGg3d/ji+AUjQMQircO8uLlNp6PvkpJi2PA/4vebpJETTMfZP/2kVV97Xa8eQEQC4soLQb6V1GlZACKUSDME7im2wEL39KkGJi1EVGSUjXWdk3Y19j+6+mxW5K5zSQezdzFiktl1pA14C/0cio+QN/Pdl02afJjOdvdeaO5CHYUpsXnt1WC3wOOkW9A1SkM8gmB/Af0EhCQLd4y5YWqPQENFW3w1g6l2TMDEv3Npj+eDN92PqmLJ5E6KBp3Hs8JI3+1XAZzJqp3h9+strqVpnb26pBzv8BFeM/kvcmnMCcA4gdtAq4YE4M2dpcalDANtwnSBe8IlO1LimIvFjaRW0JqJteB0dF5j2SpNeEvLbl8RVzwizBJnQiTkLER7E3HeTtzoF8CgTCcUaS+SEPbvLQ2k6wqeOpHDzoCwWO4Obw== rstyczynski@rstyczynski-mac"
      boot_volume_size_in_gbs = 50
    }
  }
}

