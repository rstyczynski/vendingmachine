# ═══════════════════════════════════════════════════════════════
# APP2 Compute Instances Configuration
# ═══════════════════════════════════════════════════════════════

app2_compute_instances = {
  "instance://vm_ABC/999/app2_db" = {
    zone = "zone://vm_ABC/999/infra"
    nsg  = ["nsg://vm_ABC/999/db_nsg"]

    spec = {
      shape                   = "VM.Standard.E4.Flex"
      ocpus                   = 4
      memory_in_gbs           = 64
      assign_public_ip        = false
      ssh_public_key          = "ssh-rsa AAAAB3... user@host"
      boot_volume_size_in_gbs = 200
      enable_bastion_plugin   = true
    }
  }

  "instance://vm_ABC/999/app2_web" = {
    zone = "zone://vm_ABC/999/infra"
    nsg  = ["nsg://vm_ABC/999/web_nsg"]

    spec = {
      shape                   = "VM.Standard.E4.Flex"
      ocpus                   = 2
      memory_in_gbs           = 32
      assign_public_ip        = true
      ssh_public_key          = "ssh-rsa AAAAB3... user@host"
      boot_volume_size_in_gbs = 100
      enable_bastion_plugin   = true
    }
  }

  }
