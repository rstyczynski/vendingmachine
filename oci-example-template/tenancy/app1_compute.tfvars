# ═══════════════════════════════════════════════════════════════
# APP1 Compute Instances Configuration
# ═══════════════════════════════════════════════════════════════

app1_compute_instances = {
  "instance://vm_XXX/ABC/app1_instance" = {
    zone = "zone://tmp_demo/demo/infra"
    nsg  = ["nsg://vm_XXX/ABC/ssh"]

    spec = {
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
