variable "tenancy_ocid" {
  description = "Tenancy OCID"
  type        = string
}

variable "parent_compartment_id" {
  description = "Parent compartment OCID (use tenancy_ocid for root)"
  type        = string
}

variable "name" {
  description = "Compartment name"
  type        = string
}

variable "description" {
  description = "Compartment description"
  type        = string
}

variable "enable_delete" {
  description = "Enable compartment deletion"
  type        = bool
  default     = false
}
