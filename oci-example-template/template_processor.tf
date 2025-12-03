# ═══════════════════════════════════════════════════════════════
# Terraform Template Processor
# Uses Terraform's templatefile() to generate Terraform files
# ═══════════════════════════════════════════════════════════════

# ───────────────────────────────────────────────────────────────
# Locals - Process templates into a single file map
# ───────────────────────────────────────────────────────────────

locals {
  output_dir   = "${path.module}/tenancy"
  template_dir = "${path.module}/templates"

  # Zone templates configuration
  zone_templates = [
    { key = "tf",     template = "infra_zone.tf.j2",        suffix = "_zone.tf" },
    { key = "tfvars", template = "infra_zone.tfvars.j2",    suffix = "_zone.tfvars" },
    { key = "custom", template = "infra_zone_custom.tf.j2", suffix = "_zone_custom.tf" }
  ]

  # NSG templates configuration
  nsg_templates = [
    { key = "tf",        template = "app_nsg.tf.j2",        suffix = "_nsg.tf" },
    { key = "custom_tf", template = "app_nsg_custom.tf.j2", suffix = "_nsg_custom.tf" },
    { key = "tfvars",    template = "app_nsg.tfvars.j2",    suffix = "_nsg.tfvars" }
  ]

  # App templates configuration
  app_templates = [
    { key = "tf",            template = "app_compute.tf.j2",            suffix = "_compute.tf" },
    { key = "custom_tf",     template = "app_compute_custom.tf.j2",     suffix = "_compute_custom.tf" },
    { key = "custom_tfvars", template = "app_compute_custom.tfvars.j2", suffix = "_compute.tfvars" }
  ]

  # Generate all files as a single flat map
  all_files = merge(
    # Zone files
    {
      for pair in flatten([
        for zone_key, zone in local.zones_to_generate : [
          for tmpl in local.zone_templates : {
            key      = "zone_${zone_key}_${tmpl.key}"
            filename = "${local.output_dir}/${zone.name}${tmpl.suffix}"
            content  = templatefile("${local.template_dir}/${tmpl.template}", {
              name             = zone.name
              compartment_path = zone.compartment_path
              subnet_fqrn      = zone.subnet_fqrn
              bastion_fqrn     = zone.bastion_fqrn
              ad               = zone.ad
              fqrn             = zone.fqrn
            })
            type = "zone"
          }
        ]
      ]) : pair.key => pair
    },
    # App compute files
    {
      for pair in flatten([
        for app_key, app in local.apps_to_generate : [
          for tmpl in local.app_templates : {
            key      = "app_${app_key}_${tmpl.key}"
            filename = "${local.output_dir}/${app.app_name}${tmpl.suffix}"
            content  = templatefile("${local.template_dir}/${tmpl.template}", {
              app_name         = app.app_name
              compartment_path = app.compartment_path
              zone             = app.zone
              instances        = try(app.instances, {})
              nsgs             = try(app.nsgs, {})
            })
            type = "app"
          }
        ]
      ]) : pair.key => pair
    },
    # NSG files - Generate per app group (app1, app2)
    {
      for pair in flatten([
        for app_key, app_nsgs in local.nsgs : [
          for tmpl in local.nsg_templates : {
            key      = "nsg_${app_key}_${tmpl.key}"
            filename = "${local.output_dir}/${app_key}${tmpl.suffix}"
            content  = templatefile("${local.template_dir}/${tmpl.template}", {
              app_name         = app_key
              compartment_path = try(local.apps_to_generate[app_key].compartment_path, "")
              # Normalize all NSGs in this app group with all optional attributes
              # Each NSG includes its compartment_path for FQRN generation
              nsgs = {
                for nsg_name, nsg in app_nsgs : nsg_name => {
                  compartment_path = nsg.compartment_path
                  rules = {
                    for rule_name, rule in nsg.rules : rule_name => {
                      direction        = rule.direction
                      protocol         = rule.protocol
                      source           = try(rule.source, null)
                      source_type      = try(rule.source_type, null)
                      destination      = try(rule.destination, null)
                      destination_type = try(rule.destination_type, null)
                      description      = try(rule.description, null)
                      # Normalize nested options objects
                      tcp_options = try(rule.tcp_options, null) != null ? {
                        destination_port_min = try(rule.tcp_options.destination_port_min, null)
                        destination_port_max = try(rule.tcp_options.destination_port_max, null)
                        source_port_min      = try(rule.tcp_options.source_port_min, null)
                        source_port_max      = try(rule.tcp_options.source_port_max, null)
                      } : null
                      udp_options = try(rule.udp_options, null) != null ? {
                        destination_port_min = try(rule.udp_options.destination_port_min, null)
                        destination_port_max = try(rule.udp_options.destination_port_max, null)
                        source_port_min      = try(rule.udp_options.source_port_min, null)
                        source_port_max      = try(rule.udp_options.source_port_max, null)
                      } : null
                      icmp_options = try(rule.icmp_options, null) != null ? {
                        type = rule.icmp_options.type
                        code = try(rule.icmp_options.code, null)
                      } : null
                    }
                  }
                }
              }
              zone      = null
              instances = {}
            })
            type = "nsg"
          }
        ]
      ]) : pair.key => pair
    }
  )
}

# ───────────────────────────────────────────────────────────────
# Resources - Single resource for all generated files
# ───────────────────────────────────────────────────────────────

resource "local_file" "generated" {
  for_each = local.all_files

  filename        = each.value.filename
  content         = each.value.content
  file_permission = "0644"
}

# ───────────────────────────────────────────────────────────────
# Outputs - Show what was generated
# ───────────────────────────────────────────────────────────────

output "generated_zone_files" {
  description = "List of generated zone files"
  value       = [for k, v in local.all_files : v.filename if v.type == "zone"]
}

output "generated_nsg_files" {
  description = "List of generated NSG files"
  value       = [for k, v in local.all_files : v.filename if v.type == "nsg"]
}

output "generated_app_files" {
  description = "List of generated app files"
  value       = [for k, v in local.all_files : v.filename if v.type == "app"]
}

output "generated_files" {
  description = "All generated files"
  value       = [for k, v in local.all_files : v.filename]
}
