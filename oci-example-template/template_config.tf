# ═══════════════════════════════════════════════════════════════
# Template Processor Configuration
# Define which resources to generate from templates
# ═══════════════════════════════════════════════════════════════

locals {
  zone_infra_cmp = "tmp_demo/demo"
  zone_infra1_cmp = "tmp_demo1/demo1"
  app1_cmp = "vm_XXX/ABC"
  app2_cmp = "vm_ABC/999"

  # ───────────────────────────────────────────────────────────────
  # Zones - Define zones by name and compartment_path
  # ───────────────────────────────────────────────────────────────
  zones = {
    infra = {
      compartment_path = local.zone_infra_cmp
      subnet_fqrn      = "sub://${local.zone_infra_cmp}/subnet"
      bastion_fqrn     = "bastion://${local.zone_infra_cmp}/bastion"
      ad               = 2
    }
    infra1 = {
      compartment_path = local.zone_infra1_cmp
      subnet_fqrn      = "sub://${local.zone_infra1_cmp}/subnet"
      bastion_fqrn     = "bastion://${local.zone_infra1_cmp}/bastion"
      ad               = 1
    }
  }

  # ───────────────────────────────────────────────────────────────
  # NSGs - Define NSGs by app, then by name, compartment_path, and rules
  # ───────────────────────────────────────────────────────────────
  nsgs = {
    app1 = {
      ssh = {
        compartment_path = local.app1_cmp
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
    app2 = {
      web_nsg = {
        compartment_path = local.app2_cmp
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
      db_nsg = {
        compartment_path = local.app2_cmp
        rules = {
          db_ingress = {
            direction   = "INGRESS"
            protocol    = "6" # TCP
            source      = "10.0.0.0/16"
            source_type = "CIDR_BLOCK"
            description = "Allow database access from VCN"
            tcp_options = {
              destination_port_min = 1521
              destination_port_max = 1521
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
  }

  # ───────────────────────────────────────────────────────────────
  # Zones to Generate - Derived from zones map
  # ───────────────────────────────────────────────────────────────
  # Generates zones_to_generate with name, compartment_path, and FQRN
  # from the zones map where key = name
  zones_to_generate = {
    for zone_name, zone in local.zones : zone_name => {
      fqrn             = "zone://${zone.compartment_path}/${zone_name}"
      name             = zone_name
      compartment_path = zone.compartment_path
      subnet_fqrn      = zone.subnet_fqrn
      bastion_fqrn     = zone.bastion_fqrn
      ad               = zone.ad
    }
  }

  # ───────────────────────────────────────────────────────────────
  # NSGs to Generate - Derived from nsgs map
  # ───────────────────────────────────────────────────────────────
  # Generates nsgs_to_generate with name, compartment_path, FQRN, and rules
  # from the nsgs map (flattened from app-level structure)
  # Uses composite key "${app_key}_${nsg_name}" to prevent overwrites
  nsgs_to_generate = {
    for pair in flatten([
      for app_key, app_nsgs in local.nsgs : [
        for nsg_name, nsg in app_nsgs : {
          key              = "${app_key}_${nsg_name}"
          app_key          = app_key
          fqrn             = "nsg://${nsg.compartment_path}/${nsg_name}"
          name             = nsg_name
          compartment_path = nsg.compartment_path
          rules            = nsg.rules
        }
      ]
    ]) : pair.key => {
      app_key          = pair.app_key
      fqrn             = pair.fqrn
      name             = pair.name
      compartment_path = pair.compartment_path
      rules            = pair.rules
    }
  }


  # ───────────────────────────────────────────────────────────────
  # Apps to Generate
  # ───────────────────────────────────────────────────────────────
  apps_to_generate = {
    app1 = {
      app_name         = "app1"
      compartment_path = "${local.app1_cmp}"
      zone             = "${local.zones_to_generate.infra.fqrn}"

      instances = {
        app1_instance = {
          nsg                     = ["nsg://${local.app1_cmp}/ssh"]
          shape                   = "VM.Standard.E4.Flex"
          ocpus                   = 1
          memory_in_gbs           = 16
          assign_public_ip        = false
          ssh_public_key          = "ssh-rsa AAAAB3... user@host"
          boot_volume_size_in_gbs = 50
          enable_bastion_plugin   = false
        }
      }
    }

    app2 = local.app2_config
  }

  # ───────────────────────────────────────────────────────────────
  # App2 - Using compartment_path variable for DRY configuration
  # ───────────────────────────────────────────────────────────────
  app2_compartment_path = "vm_ABC/999"

    app2_config = {
    app_name         = "app2"
    compartment_path = local.app2_compartment_path
    zone             = "zone://${local.app2_compartment_path}/infra"

    instances = {
      app2_web = {
        nsg                     = ["nsg://${local.app2_compartment_path}/web_nsg"]
        shape                   = "VM.Standard.E4.Flex"
        ocpus                   = 2
        memory_in_gbs           = 32
        assign_public_ip        = true
        ssh_public_key          = "ssh-rsa AAAAB3... user@host"
        boot_volume_size_in_gbs = 100
        enable_bastion_plugin   = true
      }
      app2_db = {
        nsg                     = ["nsg://${local.app2_compartment_path}/db_nsg"]
        shape                   = "VM.Standard.E4.Flex"
        ocpus                   = 4
        memory_in_gbs           = 64
        assign_public_ip        = false
        ssh_public_key          = "ssh-rsa AAAAB3... user@host"
        boot_volume_size_in_gbs = 200
        enable_bastion_plugin   = true
      }
    }
  }
}

  output "nsgs_to_generate" {
    value = local.nsgs_to_generate
  }
  
# ═══════════════════════════════════════════════════════════════
# Usage Instructions
# ═══════════════════════════════════════════════════════════════
#
# 1. Edit this file to define which zones and apps to generate
# 2. Run: terraform init
# 3. Run: terraform apply
# 4. Check generated files in the tenancy/ directory
#
# To add a new zone:
#   - Add entry to local.zones with compartment_path
#   - zones_to_generate is automatically derived from zones
#
# To add a new app:
#   - Add entry to local.apps_to_generate
#   - Use local.xxx_compartment_path pattern for DRY config
#
# ═══════════════════════════════════════════════════════════════

