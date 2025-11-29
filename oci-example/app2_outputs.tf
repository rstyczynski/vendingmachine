# ═══════════════════════════════════════════════════════════════
# APP2 Outputs
# ═══════════════════════════════════════════════════════════════

output "app2_nsgs" {
  description = "APP2 Network Security Group details"
  value = {
    for k, m in module.app2_nsgs : k => {
      id    = m.id
      name  = m.name
      rules = m.rules
    }
  }
}

output "app2_compute_instances" {
  description = "APP2 Compute instance details"
  value = {
    for k, m in module.app2_compute_instances : k => {
      id         = m.id
      name       = m.name
      public_ip  = m.public_ip
      private_ip = m.private_ip
      state      = m.state
    }
  }
}

