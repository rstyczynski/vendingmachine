# OCI Vending Machine

## Design Document

Version: 1.0  
Date: 2025-01-15

---

## 1. Vision

OCI Vending Machine is a framework for ordering and deploying OCI infrastructure resources through a simple, declarative approach. Like a vending machine - you specify what you want, where it goes, and how it's delivered.

---

## 2. Core Model

Four domains define every infrastructure order:

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                              OCI Vending Machine                                       │
├────────────────────┬────────────────────┬────────────────────┬─────────────────────────┤
│      FEATURE       │      ZONE(S)       │    DEPLOYMENT      │       PACKAGING         │
├────────────────────┼────────────────────┼────────────────────┼─────────────────────────┤
│ What do you want?  │ What is deployment │ Who owns?          │ How to package?         │
│ How to prepare?    │ neighbourhood?     │                    │                         │
├────────────────────┼────────────────────┼────────────────────┼─────────────────────────┤
│ resource           │ foreign OCIDs      │ state file         │ terraform               │
│ resource spec      │ variables          │ association        │ ansible                 │
│ arguments          │                    │                    │ CLI                     │
├────────────────────┼────────────────────┼────────────────────┼─────────────────────────┤
│ • resource         │ • location context │ • ownership context│ • deployment standard   │
│ • resource spec    │   - compartment    │   - git repository │   - terraform           │
│ • argument(s)      │   - subnet(s)      │   - deployment     │   - ansible             │
│                    │   - vault          │     pipeline       │   - CLI                 │
│                    │   - vcn            │   - state file     │                         │
│                    │   - nsg            │                    │                         │
│                    │   - ad             │                    │                         │
└────────────────────┴────────────────────┴────────────────────┴─────────────────────────┘
```

### 2.1 Feature

Defines WHAT to build and HOW to configure it.

| Aspect | Description |
|--------|-------------|
| Resource | Type of OCI resource (compute_instance, database, subnet, nsg, etc.) |
| Resource Spec | Configuration parameters (shape, ocpus, memory_gb, storage, etc.) |
| Argument(s) | Runtime parameters, variables |

### 2.2 Zone(s)

Defines WHERE in OCI the resource will be deployed. Location context using foreign OCIDs.

| Aspect | Description |
|--------|-------------|
| Compartment | Target compartment (FQRN) |
| Subnet(s) | Network placement (FQRN) |
| Vault | Encryption keys location (FQRN) |
| VCN | Virtual cloud network (FQRN) |
| NSG | Network security groups (FQRN list) |
| AD | Availability domain |

Zone aligns with natural OCI boundaries:
- Compartment → resource isolation
- Security Zone → policy enforcement

### 2.3 Deployment

Defines WHO owns and manages the infrastructure lifecycle.

| Aspect | Description |
|--------|-------------|
| Git Repository | Code location |
| Deployment Pipeline | CI/CD execution |
| State File | Resource tracking and state management |

Ownership context determines:
- Where code is stored
- How code is deployed
- Where state is maintained

### 2.4 Packaging

Defines HOW to deliver the infrastructure code.

| Format | Use Case |
|--------|----------|
| Terraform | Declarative IaC, state management |
| Ansible | Configuration management, procedural |
| CLI | Scripts, ad-hoc operations |

---

## 3. FQRN - Fully Qualified Resource Names

Human-readable addressing for OCI resources, avoiding raw OCIDs.

### 3.1 Syntax

```
scheme://compartment_path/resource_name
```

### 3.2 Examples

```
cmp://cmp_prod/cmp_app                              # compartment
vcn://cmp_prod/cmp_network/vcn_main                 # VCN
sub://cmp_prod/cmp_network/vcn_main/sub_private     # subnet
nsg://cmp_prod/cmp_network/vcn_main/nsg_ssh         # NSG
vault://cmp_prod/cmp_security/vault_main            # vault
drg:acme_tenancy@oc1//cmp_prod/cmp_network/drg_hub  # cross-tenancy DRG
```

### 3.3 Supported Schemes

| Scheme | OCI Resource Type |
|--------|-------------------|
| cmp:// | oci_identity_compartment |
| vcn:// | oci_core_vcn |
| sub:// | oci_core_subnet |
| nsg:// | oci_core_network_security_group |
| vault:// | oci_kms_vault |
| drg:// | oci_core_drg |

### 3.4 Resolution

FQRNs are resolved to OCIDs via data source lookups at terraform plan/apply time using all three FQRN components:

**Resolution Logic:**
1. **Scheme** (resource type) - Determines which OCI data source to use:
   - `cmp://` → `data.oci_identity_compartments`
   - `vcn://` → `data.oci_core_vcns`
   - `sub://` → `data.oci_core_subnets`
   - `nsg://` → `data.oci_core_network_security_groups`
   - `vault://` → `data.oci_kms_vaults`

2. **Compartment Path** - Resolved to compartment OCID (where to search)
3. **Resource Name** - Used as display_name filter (what to find)

**Example:** `sub://cmp_prod/cmp_network/vcn_main/sub_private`
- Scheme `sub://` → query subnets data source
- Path `cmp_prod/cmp_network/vcn_main` → resolve to compartment OCID
- Name `sub_private` → filter by display_name = "sub_private"

**Note:** Data sources cannot find resources created in the same Terraform session. See `FQRN.md` for the dual-input approach to handle same-session resource creation.

---

## 4. Architecture

### 4.1 Terraform Module Approach

No code generation. Vending machine provides reusable Terraform modules:

```
oci-vending/
└── modules/
    ├── compute_instance/
    │   ├── variables.tf     # name, spec, zone inputs
    │   ├── fqrn.tf          # FQRN resolver
    │   ├── main.tf          # resource definition
    │   └── outputs.tf
    ├── database/
    ├── subnet/
    ├── nsg/
    ├── load_balancer/
    └── bastion_session/
```

### 4.2 Module Interface Pattern

Each module receives inputs mapped to the 4 domains:

```hcl
# FEATURE - What + How
variable "name" {
  type        = string
  description = "Resource display name"
}

variable "spec" {
  type        = object({ ... })
  description = "Resource-specific configuration"
}

# ZONE - Where in OCI
variable "zone" {
  type        = object({ ... })
  description = "OCI placement context (location)"
}

# DEPLOYMENT - implicit (defined by repository where code lives)
# PACKAGING - implicit (Terraform module = terraform packaging)
```

### 4.3 Zone Schema (Location Context)

```hcl
variable "zone" {
  type = object({
    compartment   = string                    # FQRN - required
    subnet        = optional(string)          # FQRN
    nsg           = optional(list(string), [])# FQRN list
    vcn           = optional(string)          # FQRN
    vault         = optional(string)          # FQRN
    ad            = optional(number)          # availability domain (1, 2, 3)
    security_zone = optional(bool, false)
  })

  validation {
    condition     = can(regex("^cmp://", var.zone.compartment))
    error_message = "compartment must be FQRN starting with cmp://"
  }
}
```

### 4.4 Deployment Context (Ownership)

Deployment context is NOT passed to module. It's defined by WHERE the code lives:

```
┌─────────────────────────────────────────────────────────────────┐
│                   DEPLOYMENT CONTEXT                            │
│                   (Ownership - implicit)                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Git Repository    ← where .tf files are stored               │
│         │                                                       │
│         ▼                                                       │
│   Deployment Pipeline ← how terraform is executed              │
│         │                                                       │
│         ▼                                                       │
│   State File        ← backend.tf in the repository             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

When vending machine injects code, it targets a specific deployment context (repository).

---

## 5. Configuration Pattern

### 5.1 Map-Based Resources

Resources defined as maps enable:
- Multiple instances from single module definition
- Add/remove resources via configuration only
- Consistent naming via map keys

### 5.2 File Structure

```
project-infra/
├── backend.tf              # state configuration
├── providers.tf            # OCI provider
├── variables.tf            # variable schemas
├── main.tf                 # module instantiations
├── outputs.tf              # exported values
├── terraform.tfvars        # configuration data
└── environments/
    ├── dev.tfvars
    ├── test.tfvars
    └── prod.tfvars
```

### 5.3 variables.tf

```hcl
# Zone definitions
variable "zones" {
  type = map(object({
    compartment   = string
    subnet        = optional(string)
    nsg           = optional(list(string), [])
    vault         = optional(string)
    vcn           = optional(string)
    ad            = optional(number)
    security_zone = optional(bool, false)
  }))
}

# Resource definitions
variable "compute_instances" {
  type = map(object({
    zone      = string                              # zone key reference
    shape     = optional(string, "VM.Standard.E4.Flex")
    ocpus     = optional(number, 1)
    memory_gb = optional(number, 16)
    image     = optional(string, "oracle_linux_8")
    ssh_key   = optional(string)
  }))
  default = {}
}

variable "databases" {
  type = map(object({
    zone       = string
    db_name    = optional(string)
    db_version = optional(string, "19c")
    shape      = optional(string, "VM.Standard.E4.Flex")
    ocpus      = optional(number, 2)
    storage_gb = optional(number, 256)
    license    = optional(string, "LICENSE_INCLUDED")
  }))
  default = {}
}
```

### 5.4 main.tf

```hcl
module "compute" {
  source   = "github.com/rstyczynski/oci-vending/modules/compute_instance"
  for_each = var.compute_instances

  name = each.key
  spec = each.value
  zone = var.zones[each.value.zone]
}

module "database" {
  source   = "github.com/rstyczynski/oci-vending/modules/database"
  for_each = var.databases

  name = each.key
  spec = each.value
  zone = var.zones[each.value.zone]
}
```

### 5.5 terraform.tfvars

```hcl
# ═══════════════════════════════════════════════════════════════
# Zones
# ═══════════════════════════════════════════════════════════════

zones = {
  app = {
    compartment = "cmp://cmp_prod/cmp_app"
    subnet      = "sub://cmp_prod/cmp_network/vcn_main/sub_private"
    nsg         = ["nsg://cmp_prod/cmp_network/vcn_main/nsg_ssh"]
    vault       = "vault://cmp_prod/cmp_security/vault_main"
  }

  db = {
    compartment   = "cmp://cmp_prod/cmp_db"
    subnet        = "sub://cmp_prod/cmp_network/vcn_main/sub_db"
    nsg           = ["nsg://cmp_prod/cmp_network/vcn_main/nsg_db"]
    vault         = "vault://cmp_prod/cmp_security/vault_main"
    security_zone = true
    ad            = 2
  }

  mgmt = {
    compartment = "cmp://cmp_prod/cmp_mgmt"
    subnet      = "sub://cmp_prod/cmp_network/vcn_main/sub_mgmt"
    nsg         = ["nsg://cmp_prod/cmp_network/vcn_main/nsg_ssh"]
  }
}

# ═══════════════════════════════════════════════════════════════
# Compute Instances
# ═══════════════════════════════════════════════════════════════

compute_instances = {
  ansible_dev = {
    zone      = "mgmt"
    ocpus     = 2
    memory_gb = 16
  }

  jenkins = {
    zone      = "mgmt"
    ocpus     = 4
    memory_gb = 32
  }

  app_server_1 = {
    zone      = "app"
    ocpus     = 4
    memory_gb = 32
  }
}

# ═══════════════════════════════════════════════════════════════
# Databases
# ═══════════════════════════════════════════════════════════════

databases = {
  app_db = {
    zone       = "db"
    db_name    = "APPDB"
    db_version = "19c"
    ocpus      = 4
    storage_gb = 512
  }
}
```

---

## 6. FQRN Resolver Module

### 6.1 Purpose

Converts FQRN strings to OCI OCIDs via data source lookups using smart resolution logic:
- **Scheme** determines which OCI data source to query
- **Compartment path** resolves to compartment OCID (where to search)
- **Resource name** filters by display_name (what to find)

Example: `sub://cmp_prod/cmp_network/vcn_main/sub_private`
- Scheme: `sub://` → use `data.oci_core_subnets`
- Path: `cmp_prod/cmp_network/vcn_main` → resolve to compartment OCID
- Name: `sub_private` → filter where display_name = "sub_private"

### 6.2 Implementation

```hcl
# modules/fqrn_resolver/main.tf

variable "resolve" {
  type        = list(string)
  description = "List of FQRNs to resolve"
}

# Compartment resolution (uses existing module)
module "compartments" {
  source = "github.com/rstyczynski/terraform-oci-modules-iam"

  existing_compartments = [
    for fqrn in var.resolve : 
    regex("^cmp://(.+)$", fqrn)[0]
    if can(regex("^cmp://", fqrn))
  ]
}

# VCN resolution
data "oci_core_vcns" "this" {
  for_each = {
    for fqrn in var.resolve : fqrn => regex("^vcn://(.+)/([^/]+)$", fqrn)
    if can(regex("^vcn://", fqrn))
  }

  compartment_id = module.compartments.compartments["/${each.value[0]}"].id
  display_name   = each.value[1]
}

# Subnet resolution
data "oci_core_subnets" "this" {
  for_each = {
    for fqrn in var.resolve : fqrn => regex("^sub://(.+)/([^/]+)/([^/]+)$", fqrn)
    if can(regex("^sub://", fqrn))
  }

  compartment_id = module.compartments.compartments["/${each.value[0]}"].id
  vcn_id         = data.oci_core_vcns.this["vcn://${each.value[0]}/${each.value[1]}"].virtual_networks[0].id
  display_name   = each.value[2]
}

# Output: FQRN → OCID map
output "ocid" {
  value = merge(
    { for k, v in module.compartments.compartments : "cmp:/${k}" => v.id },
    { for k, v in data.oci_core_vcns.this : k => v.virtual_networks[0].id },
    { for k, v in data.oci_core_subnets.this : k => v.subnets[0].id }
  )
}
```

### 6.3 Usage in Resource Module

```hcl
# modules/compute_instance/fqrn.tf

module "fqrn" {
  source = "github.com/rstyczynski/oci-vending/modules/fqrn_resolver"

  resolve = concat(
    [var.zone.compartment],
    var.zone.subnet != null ? [var.zone.subnet] : [],
    var.zone.nsg
  )
}

locals {
  compartment_id = module.fqrn.ocid[var.zone.compartment]
  subnet_id      = var.zone.subnet != null ? module.fqrn.ocid[var.zone.subnet] : null
  nsg_ids        = [for n in var.zone.nsg : module.fqrn.ocid[n]]
}
```

---

## 7. Zone vs Deployment

### 7.1 Zone = Location Context (Where in OCI)

Zone defines OCI placement only:

```hcl
zone = {
  compartment = "cmp://cmp_prod/cmp_app"
  subnet      = "sub://cmp_prod/cmp_network/vcn_main/sub_private"
  nsg         = ["nsg://cmp_prod/cmp_network/vcn_main/nsg_ssh"]
  vault       = "vault://cmp_prod/cmp_security/vault_main"
}
```

### 7.2 Deployment = Ownership Context (Who Manages)

Deployment defines lifecycle management:

```
┌─────────────────────────────────────────────────────────────────┐
│                   DEPLOYMENT CONTEXT                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   ┌─────────────────────────────┐                               │
│   │      Git Repository         │  code location               │
│   │  git@github.com:acme/infra  │                               │
│   └──────────────┬──────────────┘                               │
│                  │                                              │
│                  ▼                                              │
│   ┌─────────────────────────────┐                               │
│   │    Deployment Pipeline      │  CI/CD execution             │
│   │  .github/workflows/tf.yml   │                               │
│   └──────────────┬──────────────┘                               │
│                  │                                              │
│                  ▼                                              │
│   ┌─────────────────────────────┐                               │
│   │       State File            │  resource tracking           │
│   │  s3://tf-state/app-team/    │                               │
│   └─────────────────────────────┘                               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 7.3 Separation of Concerns

| Aspect | Zone | Deployment |
|--------|------|------------|
| Scope | OCI resources | Code lifecycle |
| Changes | Per resource | Per team/project |
| Passed to module | Yes (variable) | No (implicit) |
| Defined in | terraform.tfvars | Repository structure |

### 7.4 Multi-Zone, Single Deployment

One deployment (repository) can manage resources across multiple zones:

```hcl
# terraform.tfvars - single deployment context

zones = {
  app  = { compartment = "cmp://prod/app",  subnet = "sub://..." }
  db   = { compartment = "cmp://prod/db",   subnet = "sub://..." }
  mgmt = { compartment = "cmp://prod/mgmt", subnet = "sub://..." }
}

compute_instances = {
  app_server = { zone = "app",  ocpus = 4 }   # zone: app
  db_server  = { zone = "db",   ocpus = 8 }   # zone: db
  ansible    = { zone = "mgmt", ocpus = 2 }   # zone: mgmt
}
# All managed by same deployment (same repo, same state)
```

### 7.5 Vending Machine Injection

When vending machine injects code:
- **Zone** = passed as configuration in tfvars
- **Deployment** = target repository where code is injected

```bash
oci-vending inject \
  --feature compute_instance \
  --spec '{"ocpus": 2, "memory_gb": 16}' \
  --zone app \
  --deployment git@github.com:acme/app-team-infra.git
```

---

## 8. Module Catalog

### 8.1 Core Modules

| Module | Zone Requirements | Description |
|--------|-------------------|-------------|
| compute_instance | compartment, subnet, nsg, ad | Virtual machine |
| database | compartment, subnet, nsg, ad | Oracle DB system |
| autonomous_database | compartment | Autonomous DB |
| subnet | compartment, vcn | Network subnet |
| nsg | compartment, vcn | Network security group |
| nsg_rule | nsg | Security rule |
| load_balancer | compartment, subnet, nsg | Load balancer |
| bastion_session | compartment, subnet | Bastion access |
| block_volume | compartment, ad | Storage volume |
| file_system | compartment, ad | File storage |

### 8.2 Module Structure

```
modules/<resource_type>/
├── variables.tf      # name, spec, zone inputs
├── fqrn.tf           # FQRN resolution
├── main.tf           # resource definition
├── data.tf           # supporting data sources
└── outputs.tf        # exported values
```

---

## 9. Summary

### 9.1 Four Domains

| Domain | Question | Answer |
|--------|----------|--------|
| Feature | What? How to prepare? | Resource + spec + arguments |
| Zone(s) | Where in OCI? | Location context (compartment, subnet, vault) |
| Deployment | Who owns? | Ownership context (repo, pipeline, state) |
| Packaging | How to package? | Deployment standard (terraform, ansible, CLI) |

### 9.2 Key Principles

| Principle | Implementation |
|-----------|----------------|
| Infrastructure as Data | Configuration in tfvars, code is static |
| Human-Readable Addressing | FQRN instead of OCIDs |
| Zone = Location | OCI placement only (compartment, subnet, etc.) |
| Deployment = Ownership | Repository, pipeline, state file |
| Map-Based Scaling | Add resources by adding map entries |
| Module Reuse | Single definition, multiple instances |

### 9.3 Change Frequency

| File | Changes | Frequency |
|------|---------|-----------|
| main.tf | Add new module type | Rare |
| variables.tf | Add new resource schema | Rare |
| terraform.tfvars | Add/remove/modify resources | Often |

### 9.4 Flow

```
terraform.tfvars          variables.tf              main.tf                 module
────────────────          ────────────              ───────                 ──────
zones = { ... }      →    var.zones            →    var.zones[key]     →   zone = { ... }
compute = { ... }    →    var.compute          →    for_each           →   name, spec
```

---

## 10. Next Steps

1. Implement FQRN Resolver module
2. Create core resource modules (compute, database, network)
3. Build module test suite
4. Document module interfaces
5. Create example deployments

---

## Appendix A: Terminology

| Term | Definition |
|------|------------|
| Feature | What to build (resource + spec + arguments) |
| Zone | Where in OCI (location context - compartment, subnet, vault, etc.) |
| Deployment | Who owns (ownership context - git repo, pipeline, state file) |
| Packaging | How to deliver (deployment standard - Terraform/Ansible/CLI) |
| FQRN | Fully Qualified Resource Name - human-readable OCI addressing |
| Location Context | OCI placement - foreign OCIDs (compartment, subnet, nsg, vault) |
| Ownership Context | Code lifecycle - git repository, deployment pipeline, state file |

## Appendix B: Related Projects

- [terraform-oci-modules-iam](https://github.com/rstyczynski/terraform-oci-modules-iam) - Compartment path resolution
