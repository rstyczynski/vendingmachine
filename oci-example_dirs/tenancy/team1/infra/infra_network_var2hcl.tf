# ═══════════════════════════════════════════════════════════════
# Variable Proxy Layer: Network (VCNs and Subnets)
# Transforms variables into locals for use by modules/resources
# This layer can be modified to augment variables using HCL methods
# ═══════════════════════════════════════════════════════════════

locals {
  # Proxy layer: Transform VCN variables into locals
  vcns_var2hcl = {
    for k, v in var.vcns : k => {
      vcn_fqrn                = k # VCN FQRN is the map key (e.g., "vcn://team1/demo_vcn")
      cidr_blocks             = v.cidr_blocks
      dns_label               = v.dns_label
      create_internet_gateway = v.create_internet_gateway
      create_service_gateway  = v.create_service_gateway
      service_gateway_services = v.service_gateway_services
      create_nat_gateway      = v.create_nat_gateway
    }
  }

  # Proxy layer: Transform subnet variables into locals
  subnets_var2hcl = {
    for k, v in var.subnets : k => {
      subnet_fqrn             = k # Subnet FQRN is the map key (e.g., "sub://team1/demo_vcn/public_subnet")
      cidr_block             = v.cidr_block
      dns_label              = v.dns_label
      prohibit_public_ip_on_vnic = v.prohibit_public_ip_on_vnic
      use_service_gateway_rt     = v.use_service_gateway_rt
      use_nat_gateway_rt         = v.use_nat_gateway_rt
      enable_flow_log            = v.enable_flow_log
      flow_log_display_name      = v.flow_log_display_name
      flow_log_log_group_id      = v.flow_log_log_group_id
      flow_log_log_group_fqrn    = v.flow_log_log_group_fqrn
    }
  }
}

