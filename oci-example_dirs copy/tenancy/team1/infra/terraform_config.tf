# ═══════════════════════════════════════════════════════════════
# Provider Configuration
# ═══════════════════════════════════════════════════════════════
# Note: required_providers must use literal values (Terraform limitation)
# To change provider configuration, update the values in required_providers below

terraform {
  required_version = ">= 1.0"

  required_providers {
    oci = {
      source  = "oracle/oci"  # Use oracle/oci (not hashicorp/oci) - controlled by var.oci_provider_source (reference only)
      version = "~> 7.0"      # Version constraint - controlled by var.oci_provider_version (reference only)
    }
  }
}

provider "oci" {
  
}

terraform {
  backend "local" {
    path = "state/terraform.tfstate"
  }
}

