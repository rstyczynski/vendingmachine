# OCI Vending Machine - Chat Summary

## Purpose
Summary of design conversation for continuation in Claude Code environment.

---

## Project Overview

**Goal:** Build "OCI Vending Machine" - a framework for ordering and deploying OCI infrastructure resources through declarative approach.

**Repository Reference:** [terraform-oci-modules-iam](https://github.com/rstyczynski/terraform-oci-modules-iam) - existing FQRN compartment path module.

---

## Final 4-Domain Model

```
┌────────────────────┬────────────────────┬────────────────────┬─────────────────────────┐
│      FEATURE       │      ZONE(S)       │    DEPLOYMENT      │       PACKAGING         │
├────────────────────┼────────────────────┼────────────────────┼─────────────────────────┤
│ What do you want?  │ What is deployment │ Who owns?          │ How to package?         │
│ How to prepare?    │ neighbourhood?     │                    │                         │
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

---

## Key Design Decisions

### 1. FQRN (Fully Qualified Resource Names)
Human-readable OCI addressing instead of raw OCIDs:
```
cmp://cmp_prod/cmp_app                              # compartment
vcn://cmp_prod/cmp_network/vcn_main                 # VCN
sub://cmp_prod/cmp_network/vcn_main/sub_private     # subnet
nsg://cmp_prod/cmp_network/vcn_main/nsg_ssh         # NSG
vault://cmp_prod/cmp_security/vault_main            # vault
```

### 2. Terraform Module Approach (Not Code Generation)
- No Jinja2 templates or code generation
- Reusable Terraform modules
- Users call modules directly
- FQRN resolution via data sources inside modules

### 3. Map-Based Configuration
Resources defined as maps in tfvars enable N instances from single module:
```hcl
compute_instances = {
  vm1 = { zone = "app", ocpus = 2 }
  vm2 = { zone = "app", ocpus = 4 }
  vm3 = { zone = "db",  ocpus = 8 }
}
```

### 4. Zone = Location Context Only
Zone is WHERE in OCI (not ownership):
```hcl
zone = {
  compartment = "cmp://cmp_prod/cmp_app"
  subnet      = "sub://cmp_prod/cmp_network/vcn_main/sub_private"
  nsg         = ["nsg://cmp_prod/cmp_network/vcn_main/nsg_ssh"]
}
```

### 5. Deployment = Ownership (Implicit)
Ownership defined by repository location, not passed to module:
- Git repository (where code lives)
- Deployment pipeline (CI/CD)
- State file (backend.tf)

### 6. Naming Decision
Rejected names: "Landing Zone" (buzzword), "Drop Zone" (military)
Accepted: "Neighborhood" for friendly term, but final model uses "Zone(s)" for location context

---

## Implementation Pattern

### Module Interface
```hcl
module "compute" {
  source   = "github.com/rstyczynski/oci-vending/modules/compute_instance"
  for_each = var.compute_instances

  name = each.key
  spec = each.value
  zone = var.zones[each.value.zone]
}
```

### terraform.tfvars Structure
```hcl
# Zones (location contexts)
zones = {
  app = {
    compartment = "cmp://cmp_prod/cmp_app"
    subnet      = "sub://cmp_prod/cmp_network/vcn_main/sub_private"
    nsg         = ["nsg://cmp_prod/cmp_network/vcn_main/nsg_ssh"]
  }
  db = {
    compartment = "cmp://cmp_prod/cmp_db"
    subnet      = "sub://cmp_prod/cmp_network/vcn_main/sub_db"
    nsg         = ["nsg://cmp_prod/cmp_network/vcn_main/nsg_db"]
  }
}

# Resources (map = multiple instances)
compute_instances = {
  ansible_dev = { zone = "app", ocpus = 2, memory_gb = 16 }
  jenkins     = { zone = "app", ocpus = 4, memory_gb = 32 }
}

databases = {
  app_db = { zone = "db", db_version = "19c", storage_gb = 512 }
}
```

---

## Repository Structure

```
oci-vending/
└── modules/
    ├── compute_instance/
    │   ├── variables.tf     # name, spec, zone
    │   ├── fqrn.tf          # FQRN resolver
    │   ├── main.tf          # resource
    │   └── outputs.tf
    ├── database/
    ├── subnet/
    ├── nsg/
    ├── load_balancer/
    └── bastion_session/
```

---

## FQRN Resolver Concept

Data source based resolution using all three FQRN components (no wiring files needed):

**FQRN syntax:** `scheme://compartment_path/resource_name`

**Resolution logic:**
- Scheme (resource type) → determines OCI data source
- Compartment path → resolves to compartment OCID
- Resource name → filters by display_name

Example: `sub://cmp_prod/cmp_network/vcn_main/sub_private`
1. Scheme `sub://` → use data.oci_core_subnets
2. Path `cmp_prod/cmp_network/vcn_main` → compartment OCID
3. Name `sub_private` → display_name filter

Uses existing module: `github.com/rstyczynski/terraform-oci-modules-iam`

**Note:** See FQRN.md for same-session resolution problem and dual-input solution.

---

## Next Steps for Implementation

1. **FQRN Resolver Module** - extend compartment module for VCN, subnet, NSG
2. **Core Resource Modules** - compute_instance, database, subnet, nsg
3. **Example Deployment** - sample tfvars and module calls
4. **Documentation** - module interface docs

---

## Files Generated

1. `oci-vending-machine-design.md` - Full design document
2. `oci-vending-machine-chat-summary.md` - This summary

---

## Key Quotes from Discussion

- "Ownership context means we are going to inject TF file into someone's repository"
- "Zone aligns naturally with OCI: Compartment boundary = Team boundary = Security Zone"
- "Maps everywhere = flexible, scalable, composable"
- "Infrastructure as data. Code stays static. Configuration drives everything."