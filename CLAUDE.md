# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**OCI Vending Machine** is a framework for ordering and deploying Oracle Cloud Infrastructure (OCI) resources through a declarative, human-readable approach. This is a design and planning repository - actual Terraform modules will be implemented in separate repositories.

**Key Principle:** Infrastructure as data. Code stays static, configuration drives everything.

## Core Architecture - The 4-Domain Model

Every infrastructure request is defined by four domains:

1. **FEATURE** - What to build (resource type + spec + arguments)
2. **ZONE(S)** - Where in OCI (location context: compartment, subnet, NSG, vault, VCN, AD)
3. **DEPLOYMENT** - Who owns (ownership context: git repo, CI/CD pipeline, state file)
4. **PACKAGING** - How to deliver (Terraform, Ansible, or CLI)

### Critical Design Decisions

**FQRN (Fully Qualified Resource Names):**
Human-readable addressing instead of raw OCIDs:
```
cmp://cmp_prod/cmp_app                              # compartment
vcn://cmp_prod/cmp_network/vcn_main                 # VCN
sub://cmp_prod/cmp_network/vcn_main/sub_private     # subnet
nsg://cmp_prod/cmp_network/vcn_main/nsg_ssh         # NSG
vault://cmp_prod/cmp_security/vault_main            # vault
```

**Zone = Location Context ONLY:**
Zone defines WHERE in OCI, not ownership. Ownership is implicit from repository location.

**Map-Based Configuration:**
Resources defined as maps in tfvars enable N instances from a single module definition:

```hcl
compute_instances = {
  vm1 = { zone = "app", ocpus = 2 }
  vm2 = { zone = "app", ocpus = 4 }
  vm3 = { zone = "db",  ocpus = 8 }
}
```

**Terraform Module Approach (NOT Code Generation):**
- No Jinja2 templates or code generation
- Reusable Terraform modules with `for_each`
- Users call modules directly
- FQRN resolution via data sources inside modules

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

**Resolution uses all three components:**
- **Scheme** - Resource type (cmp, vcn, sub, nsg, vault, drg) determines which OCI data source to query
- **Compartment path** - Where to search (resolved to compartment OCID)
- **Resource name** - What to find (display_name filter)

Example: `sub://cmp_prod/cmp_network/vcn_main/sub_private`
1. Scheme `sub://` → use `data.oci_core_subnets`
2. Path `cmp_prod/cmp_network/vcn_main` → resolve to compartment OCID
3. Name `sub_private` → filter by display_name

**Same-Session Resolution Problem:**
Data sources execute at plan start, BEFORE resources are created. Resources created in the same session cannot be found by data sources.

**Solution: Dual-Input Approach** (from terraform-oci-modules-iam):
- `existing_*` lists - Resources that already exist (resolved via data sources)
- `*` maps - Resources to create in this session (created as resources)
- Unified output - Merged map provides OCIDs for both existing and new resources

Reference module for compartment resolution: `github.com/rstyczynski/terraform-oci-modules-iam`

See `FQRN.md` for complete resolution details.

## Repository Structure

This is a design repository. Implementation repositories will follow:

```
oci-vending/
└── modules/
    ├── fqrn_resolver/      # FQRN to OCID resolution
    ├── compute_instance/   # VM instances
    ├── database/           # Oracle DB systems
    ├── subnet/             # Network subnets
    ├── nsg/                # Network security groups
    ├── load_balancer/      # Load balancers
    └── bastion_session/    # Bastion access
```

Each module contains:
- `variables.tf` - name, spec, zone inputs
- `fqrn.tf` - FQRN resolution logic
- `main.tf` - resource definition
- `outputs.tf` - exported values

## Separation: Zone vs Deployment

**Zone (Location Context):**
- Passed to module as variable
- Defines WHERE in OCI
- Changes per resource
- Example: compartment, subnet, NSG

**Deployment (Ownership Context):**
- NOT passed to module (implicit)
- Defined by repository location
- Changes per team/project
- Example: git repo, pipeline, state file

One deployment can manage resources across multiple zones.

## Configuration Pattern

**variables.tf** - Define schemas for zones and resources as maps

**main.tf** - Static module calls with `for_each` over resource maps

**terraform.tfvars** - Data-driven configuration (changes frequently)
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

## Key Terminology

- **FQRN** - Fully Qualified Resource Name (human-readable OCI addressing)
- **Zone** - Location context (WHERE in OCI)
- **Deployment** - Ownership context (WHO manages, WHERE code lives)
- **Feature** - Resource specification (WHAT to build)
- **Packaging** - Delivery method (HOW - Terraform/Ansible/CLI)

## Implementation Priority

1. FQRN Resolver module - extend for VCN, subnet, NSG, vault
2. Core resource modules - compute_instance, database, subnet, nsg
3. Example deployments - sample tfvars demonstrating map-based pattern
4. Module documentation - interface specifications

## Design Documents

- `oci-vending-machine-design v1.md` - Complete design specification
- `CLAUDE_chat.md` - Design conversation summary
- `CLAUDE.md` - This file (working guidance for Claude Code)

## Reference Project

Existing compartment path resolution module: https://github.com/rstyczynski/terraform-oci-modules-iam
