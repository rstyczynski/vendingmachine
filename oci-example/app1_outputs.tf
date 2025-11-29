# ═══════════════════════════════════════════════════════════════
# APP1 Outputs
# ═══════════════════════════════════════════════════════════════

output "app1_nsgs" {
  description = "APP1 Network Security Group details"
  value = {
    for k, m in module.app1_nsgs : k => {
      id    = m.id
      name  = m.name
      rules = m.rules
    }
  }
}

output "app1_compute_instances" {
  description = "APP1 Compute instance details"
  value = {
    for k, m in module.app1_compute_instances : k => {
      id         = m.id
      name       = m.name
      public_ip  = m.public_ip
      private_ip = m.private_ip
      state      = m.state
    }
  }
}

