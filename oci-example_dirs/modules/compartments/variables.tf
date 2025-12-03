variable "tenancy_ocid" {
  description = "Tenancy OCID"
  type        = string
}

variable "compartments" {
  description = "Map of compartment FQRNs to compartment configurations"
  type = map(object({
    description   = string
    enable_delete = bool
  }))
}

