variable "log_group_fqrn" {
  description = "Log group FQRN (e.g., log_group://vm_demo/demo/demo_log_group)"
  type        = string
}

variable "fqrn_map" {
  description = "FQRN → OCID map from previous resources"
  type        = map(string)
  default     = {}
}

variable "description" {
  description = "Log group description"
  type        = string
  default     = null
}

