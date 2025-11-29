# ═══════════════════════════════════════════════════════════════
# Infrastructure Variables
# Tenancy, region, compartments, VCNs, subnets - shared by all applications
# ═══════════════════════════════════════════════════════════════

variable "tenancies" {
  description = "Map of tenancies, indexed by tenancy FQRN (e.g., tenancy://oc1/avq3)"
  type = map(object({
    description   = string
    tenancy_ocid  = string
  }))
  default = {}
}

variable "tenancy" {
  description = "Tenancy FQRN to use (must exist in tenancies map)"
  type        = string
}

variable "regions" {
  description = "Map of regions, indexed by region FQRN (e.g., region://oc1/eu-zurich-1)"
  type = map(object({
    description = string
  }))
  default = {}
}

variable "region" {
  description = "Region FQRN to use (must exist in regions map)"
  type        = string
}

variable "compartments" {
  description = "Map of compartments to create"
  type = map(object({
    description   = string
    enable_delete = optional(bool, false)
  }))
  default = {}
}

variable "vcns" {
  description = "Map of VCNs to create"
  type = map(object({
    cidr_blocks             = optional(list(string), ["10.0.0.0/16"])
    dns_label               = optional(string)
    create_internet_gateway = optional(bool, true)
  }))
  default = {}
}

variable "subnets" {
  description = "Map of subnets to create, indexed by subnet FQRN (e.g., sub://vm_demo/demo/demo_vcn/public_subnet)"
  type = map(object({
    cidr_block                 = string
    dns_label                  = optional(string)
    prohibit_public_ip_on_vnic = optional(bool, false)
  }))
  default = {}
}

variable "zones" {
  description = "Shared zones (location contexts) used by all applications"
  type = map(object({
    # compartment is optional because it is in FQRN URI already
    compartment = optional(string) # FQRN: cmp://...
    subnet      = string # FQRN: sub://...
    # ad is a number that is mapped to the availability domain name
    ad          = number # Availability domain: 0, 1, or 2
  }))
  default = {}
}

