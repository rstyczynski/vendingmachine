# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

OCI Vending Machine is a framework for ordering and deploying Oracle Cloud Infrastructure (OCI) resources through a declarative, human-readable approach. The repository contains design documentation and a working reference implementation in the oci-example directory.

Key principle: Infrastructure as data. Code stays static, configuration drives everything.

## Core Architecture - The 4-Domain Model

Every infrastructure request is defined by four domains:

- FEATURE - What to build (resource type, specification, arguments)
- ZONE(S) - Where in OCI (location context: compartment, subnet, NSG, vault, VCN, AD)
- DEPLOYMENT - Who owns (ownership context: git repo, CI/CD pipeline, state file)
- PACKAGING - How to deliver (Terraform, Ansible, or CLI)

## Critical Design Decisions

FQRN (Fully Qualified Resource Names) - Human-readable addressing instead of raw OCIDs:
```
cmp://cmp_prod/cmp_app                              # compartment
vcn://cmp_prod/cmp_network/vcn_main                 # VCN
sub://cmp_prod/cmp_network/vcn_main/sub_private     # subnet
nsg://cmp_prod/cmp_network/vcn_main/nsg_ssh         # NSG
vault://cmp_prod/cmp_security/vault_main            # vault
```

Zone = Location Context ONLY - Zone defines WHERE in OCI, not ownership. Ownership is implicit from repository location.

Map-Based Configuration - Resources defined as maps in tfvars enable N instances from a single module definition:

```hcl
compute_instances = {
  vm1 = { zone = "app", ocpus = 2 }
  vm2 = { zone = "app", ocpus = 4 }
  vm3 = { zone = "db",  ocpus = 8 }
}
```

Terraform module approach with selective automation:
- Reusable Terraform modules are hand-written (no code generation for modules themselves)
- Modules use `for_each` for multi-instance deployments
- FQRN resolution via aggregated maps passed to modules
- Auto-generation is used only for orchestration files (terraform_fqrn.tf, terraform.tfvars) to support multi-app deployments

## Module Interface Pattern

Every vending machine module follows this interface:

```hcl
variable "name" {
  type        = string
  description = "Resource display name"
}

variable "spec" {
  type        = object({ ... })
  description = "Resource-specific configuration"
}

variable "zone" {
  type = object({
    compartment   = string                    # FQRN - required
    subnet        = optional(string)          # FQRN
    nsg           = optional(list(string), [])# FQRN list
    vcn           = optional(string)          # FQRN
    vault         = optional(string)          # FQRN
    ad            = optional(number)          # 1, 2, or 3
    security_zone = optional(bool, false)
  })
}
```

Usage in main.tf:
```hcl
module "compute" {
  source   = "github.com/rstyczynski/oci-vending/modules/compute_instance"
  for_each = var.compute_instances

  name = each.key
  spec = each.value
  zone = var.zones[each.value.zone]
}
```

## FQRN Resolution

FQRN syntax: `scheme://compartment_path/resource_name`

Resolution uses all three components:
- Scheme - Resource type (cmp, vcn, sub, nsg, vault, drg) determines which OCI data source to query
- Compartment path - Where to search (resolved to compartment OCID)
- Resource name - What to find (display_name filter)

Example: `sub://cmp_prod/cmp_network/vcn_main/sub_private`
1. Scheme `sub://` → use `data.oci_core_subnets`
2. Path `cmp_prod/cmp_network/vcn_main` → resolve to compartment OCID
3. Name `sub_private` → filter by display_name

Same-session resolution approach: Layered FQRN map aggregation solves the problem of resources created in the same Terraform session. Each infrastructure layer outputs FQRN→OCID mappings, which are merged and passed to dependent layers. This enables immediate resolution without data sources.

Example flow:
- Layer 1 creates compartments → outputs compartment FQRNs
- Layer 2 creates VCNs using compartment FQRNs → outputs VCN FQRNs
- Layer 3 creates subnets using compartment + VCN FQRNs → outputs subnet FQRNs
- Layer 4 creates compute instances using all network FQRNs

The unified FQRN map is automatically aggregated in terraform_fqrn.tf (auto-generated file) and provides same-session resolution for all resources.

See FQRN.md for complete resolution details and pattern specifications.

## Repository Structure

The repository contains design documents at the root level and a working reference implementation in oci-example:

```
vendingmachine/
├── *.md                    # Design documentation
├── oci-example/            # Reference implementation
│   ├── modules/
│   │   ├── compartment/    # Single compartment module
│   │   ├── compartments/   # Multi-compartment module
│   │   ├── vcn/            # Virtual Cloud Networks
│   │   ├── subnet/         # Network subnets
│   │   ├── nsg/            # Network security groups
│   │   ├── compute_instance/ # VM instances
│   │   ├── bastion/        # Bastion hosts
│   │   └── log_group/      # Logging infrastructure
│   ├── bin/
│   │   ├── generate_fqrn.sh      # Auto-generates terraform_fqrn.tf
│   │   ├── generate_tfvars.sh    # Auto-generates terraform.tfvars
│   │   ├── add_compute.sh        # Helper for adding compute instances
│   │   └── bastion_ssh_config.sh # Bastion SSH configuration
│   ├── templates/
│   │   ├── terraform_fqrn.tf.j2     # Template for FQRN map aggregation
│   │   ├── app_compute.tf.j2        # Template for app compute resources
│   │   └── app_compute.tfvars.j2    # Template for app variables
│   ├── infra_*.tf          # Shared infrastructure (compartments, VCN, subnets)
│   ├── app1_*.tf           # Application 1 resources (NSGs, compute)
│   ├── app2_*.tf           # Application 2 resources
│   ├── app3_*.tf           # Application 3 resources
│   ├── web1_*.tf           # Web application resources
│   ├── terraform_fqrn.tf   # Auto-generated FQRN map aggregation
│   └── terraform.tfvars    # Auto-generated combined configuration
```

Each module contains:
- variables.tf - Module inputs (typically: name, spec, zone, fqrn_map)
- main.tf - Resource definitions
- outputs.tf - FQRN map and resource attributes

## Multi-Application Deployment Pattern

The reference implementation demonstrates managing multiple applications in a single Terraform workspace with clear separation:

Shared infrastructure (infra_*.tf files):
- Managed by platform team
- Defines compartments, VCNs, subnets, bastion hosts
- Changes infrequently

Application-specific resources (app*_*.tf files):
- Owned by application teams
- Defines NSGs and compute instances per application
- Each app has separate .tf and .tfvars files
- Apps can reference each other's NSGs via FQRNs

Auto-generated orchestration:
- terraform_fqrn.tf - Aggregates FQRN maps from all modules (generated by bin/generate_fqrn.sh)
- terraform.tfvars - Combines all *_terraform.tfvars files (generated by bin/generate_tfvars.sh)

Adding a new application requires only creating new app files and running generation scripts. No manual editing of shared files needed.

## Separation: Zone vs Deployment

Zone (location context):
- Passed to module as variable
- Defines WHERE in OCI
- Changes per resource
- Example: compartment, subnet, NSG

Deployment (ownership context):
- NOT passed to module, implicit from repository location
- Defines WHO manages the resources
- Changes per team or project
- Example: git repo, pipeline, state file

One deployment can manage resources across multiple zones and multiple applications.

## Configuration Pattern

The framework separates code from data using a three-file pattern:

- variables.tf - Define schemas for zones and resources as maps
- main.tf - Static module calls with `for_each` over resource maps
- terraform.tfvars - Data-driven configuration (changes frequently)

Example configuration:
```hcl
zones = {
  app = { compartment = "cmp://...", subnet = "sub://...", nsg = [...] }
  db  = { compartment = "cmp://...", subnet = "sub://...", nsg = [...] }
}

compute_instances = {
  ansible_dev = { zone = "app", ocpus = 2, memory_gb = 16 }
  jenkins     = { zone = "app", ocpus = 4, memory_gb = 32 }
}
```

## Automation Scripts

The reference implementation includes helper scripts in oci-example/bin:

generate_fqrn.sh - Auto-generates terraform_fqrn.tf from module references found in Terraform files. Uses Python script and Jinja2 template. Creates virtual environment automatically. Run after adding new applications.

generate_tfvars.sh - Combines all *_terraform.tfvars files into a single terraform.tfvars. Run after modifying any .tfvars file.

add_compute.sh - Interactive script to add new compute instances to an application. Generates necessary configuration entries.

bastion_ssh_config.sh - Configures SSH access through OCI bastion service. Manages session creation and SSH config.

terraform_prepare.sh - Validates and prepares Terraform configuration before deployment.

## Key Terminology

FQRN - Fully Qualified Resource Name, human-readable OCI addressing scheme
Zone - Location context, defines WHERE in OCI
Deployment - Ownership context, defines WHO manages and WHERE code lives
Feature - Resource specification, defines WHAT to build
Packaging - Delivery method, defines HOW (Terraform, Ansible, or CLI)

## Implementation Status

Completed modules:
- compartment, compartments - Compartment management
- vcn - Virtual Cloud Networks with Internet Gateway
- subnet - Network subnets
- nsg - Network Security Groups with rule management
- compute_instance - VM instances
- bastion - Bastion host management
- log_group - Logging infrastructure

Demonstrated patterns:
- FQRN-based resource references
- Layered FQRN map aggregation for same-session resolution
- Multi-application deployment in single workspace
- Auto-generation of orchestration files
- Cross-application resource references

Potential future modules:
- Database systems
- Load balancers
- Object storage
- Vault integration

## Documentation Files

Design and architecture:
- oci-vending-machine-design v1.md - Complete design specification
- CLAUDE_chat.md - Design conversation summary
- CLAUDE.md - This file, working guidance for Claude Code
- FQRN.md - FQRN syntax and resolution patterns
- NSG.md - Network Security Groups architecture
- MODULE_INTEGRATION.md - Module integration patterns

Implementation guides:
- oci-example/README.md - Reference implementation overview
- MULTI_APP.md - Multi-application deployment guide
- README_GENERATION.md - Auto-generation scripts documentation

## Working with This Repository

When modifying the oci-example implementation:
- Edit module code directly in oci-example/modules/
- Edit infrastructure definitions in infra_*.tf files
- Edit application configurations in app*_*.tf and app*_*.tfvars files
- Run bin/generate_fqrn.sh after adding new modules or applications
- Run bin/generate_tfvars.sh after modifying .tfvars files
- Never manually edit terraform_fqrn.tf or terraform.tfvars (auto-generated)

When adding new design patterns:
- Update relevant .md files in repository root
- Add examples to oci-example if demonstrating new patterns
- Update CLAUDE.md to reflect architectural changes
