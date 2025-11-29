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

# ═══════════════════════════════════════════════════════════════
# APP1 Configuration
# ═══════════════════════════════════════════════════════════════

# APP1 Network Security Groups (NSGs)
app1_nsgs = {
  "nsg://vm_demo/demo/demo_vcn/ssh" = {
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

# APP1 Compute Instances
app1_compute_instances = {
  "instance://vm_demo/demo/demo_instance" = {
    zone = "zone://vm_demo/demo/app" # Zone map key reference (for subnet, AD)
    
    nsg  = [
      "nsg://vm_demo/demo/demo_vcn/ssh", 
      "nsg://vm_demo/demo/demo_vcn/app2_web"
    ] # NSG FQRN list (co-resource, not part of zone) - can reference APP2 NSGs

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

