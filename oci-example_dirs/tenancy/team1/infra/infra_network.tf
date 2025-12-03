module "vcns" {
  source   = "./modules/vcn"
  for_each = local.vcns_var2hcl

  # Pass locals (from proxy layer), NOT variables directly
  vcn_fqrn                = each.value.vcn_fqrn
  fqrn_map                = local.compartments_fqrns # Pass compartment FQRNs - Terraform auto-infers dependency on module.compartments
  cidr_blocks             = each.value.cidr_blocks
  dns_label               = each.value.dns_label
  create_internet_gateway = each.value.create_internet_gateway
  create_service_gateway  = each.value.create_service_gateway
  service_gateway_services = each.value.service_gateway_services
  create_nat_gateway      = each.value.create_nat_gateway

  # depends_on not needed: local.compartment_fqrns = module.compartments.fqrn_map creates automatic dependency
}

# ═══════════════════════════════════════════════════════════════
# LAYER 3: Subnets (depends on compartments + VCNs)
# ═══════════════════════════════════════════════════════════════

# Map subnet FQRNs to their VCN's route table IDs
locals {
  # Extract VCN FQRN from subnet FQRN: sub://compartment_path/vcn_name/subnet_name -> vcn://compartment_path/vcn_name
  vcn_fqrn_from_subnet = {
    for subnet_fqrn in keys(local.subnets_var2hcl) : subnet_fqrn => "vcn://${regex("^sub://(.+)/([^/]+)/", subnet_fqrn)[0]}/${regex("^sub://(.+)/([^/]+)/", subnet_fqrn)[1]}"
  }
  
  # Service gateway route table mapping
  # Used when IGW is enabled (since IGW and SGW "All Services" cannot be in same RT per OCI limitation)
  # This RT includes both SGW and NAT routes (NAT + SGW can coexist)
  subnet_vcn_service_gateway_rt = {
    for subnet_fqrn, subnet_config in local.subnets_var2hcl : subnet_fqrn => try(
      module.vcns[local.vcn_fqrn_from_subnet[subnet_fqrn]].service_gateway_route_table_id,
      null
    ) if subnet_config.use_service_gateway_rt
  }
  
  # NAT gateway route table mapping
  # Only used when NAT is enabled but IGW and SGW are NOT enabled
  # When IGW is NOT enabled, NAT and SGW routes are in the default route table
  subnet_vcn_nat_gateway_rt = {
    for subnet_fqrn, subnet_config in local.subnets_var2hcl : subnet_fqrn => try(
      module.vcns[local.vcn_fqrn_from_subnet[subnet_fqrn]].nat_gateway_route_table_id,
      null
    ) if subnet_config.use_nat_gateway_rt
  }
  
  # Combined route table mapping
  # Priority: service_gateway_rt (if IGW enabled and SGW enabled) > nat_gateway_rt (if NAT only, no IGW/SGW) > null
  subnet_route_table_id = {
    for subnet_fqrn in keys(local.subnets_var2hcl) : subnet_fqrn => try(
      local.subnet_vcn_service_gateway_rt[subnet_fqrn],
      local.subnet_vcn_nat_gateway_rt[subnet_fqrn],
      null
    )
  }
}

module "subnets" {
  source   = "./modules/subnet"
  for_each = local.subnets_var2hcl

  # Pass locals (from proxy layer), NOT variables directly
  subnet_fqrn             = each.value.subnet_fqrn
  fqrn_map               = merge(
    local.compartment_and_vcn_fqrns,
    local.log_groups_fqrns
  ) # Pass compartment + VCN + log group FQRNs - Terraform auto-infers dependencies
  cidr_block             = each.value.cidr_block
  dns_label              = each.value.dns_label
  prohibit_public_ip_on_vnic = each.value.prohibit_public_ip_on_vnic
  route_table_id         = try(local.subnet_route_table_id[each.key], null)
  enable_flow_log        = each.value.enable_flow_log
  flow_log_display_name  = each.value.flow_log_display_name
  flow_log_log_group_id  = each.value.flow_log_log_group_id
  flow_log_log_group_fqrn = each.value.flow_log_log_group_fqrn

  # depends_on not needed: 
  # - local.compartment_and_vcn_fqrns depends on module.compartments and module.vcns
  # - local.log_group_fqrns depends on module.log_groups
  # - local.subnet_route_table_id references module.vcns outputs
  # All dependencies are automatically inferred from these references
}


variable "vcns" {
  description = "Map of VCNs to create"
  type = map(object({
    cidr_blocks             = optional(list(string), ["10.0.0.0/16"])
    dns_label               = optional(string)
    create_internet_gateway = optional(bool, true)
    create_service_gateway   = optional(bool, false) # Create service gateway for OCI services access
    service_gateway_services = optional(list(string), []) # Service names to enable (empty = all services)
    create_nat_gateway      = optional(bool, false) # Create NAT gateway for private subnets to access internet
  }))
  default = {}
}

variable "subnets" {
  description = "Map of subnets to create, indexed by subnet FQRN (e.g., sub://team1/demo_vcn/public_subnet)"
  type = map(object({
    cidr_block                 = string
    dns_label                  = optional(string)
    prohibit_public_ip_on_vnic = optional(bool, false)
    use_service_gateway_rt     = optional(bool, false) # Use service gateway route table (for private subnets accessing OCI services). When IGW is enabled, this RT includes SGW+NAT. When IGW is disabled, use use_nat_gateway_rt instead (which includes NAT+SGW).
    use_nat_gateway_rt         = optional(bool, false) # Use NAT gateway route table (for private subnets to access internet). Only used when IGW is NOT enabled. This RT includes NAT+SGW routes.
    enable_flow_log            = optional(bool, false) # Enable VCN flow logs for this subnet
    flow_log_display_name      = optional(string)      # Display name for flow log (defaults to subnet name + '-flow-log')
    flow_log_log_group_id      = optional(string)      # OCID of log group for flow logs (alternative to flow_log_log_group_fqrn)
    flow_log_log_group_fqrn    = optional(string)      # FQRN of log group for flow logs (e.g., log_group://team1/demo_log_group)
  }))
  default = {}
}

output "vcns" {
  description = "VCN details"
  value = {
    for k, m in module.vcns : k => {
      id                  = m.id
      name                = m.name
      internet_gateway_id = m.internet_gateway_id
    }
  }
}

output "subnets" {
  description = "Subnet details"
  value = {
    for k, m in module.subnets : k => {
      id   = m.id
      name = m.name
    }
  }
}