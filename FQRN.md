# FQRN Summary

**FQRN (Fully Qualified Resource Names)** is a human-readable addressing scheme for OCI resources, replacing raw OCIDs.

## Syntax

```text
scheme://compartment_path/resource_name
```

## Examples

```text
cmp://cmp_prod/cmp_app                              # compartment
vcn://cmp_prod/cmp_network/vcn_main                 # VCN
sub://cmp_prod/cmp_network/vcn_main/sub_private     # subnet
nsg://cmp_prod/cmp_network/vcn_main/nsg_ssh         # NSG
vault://cmp_prod/cmp_security/vault_main            # vault
```

## Supported Schemes

- `cmp://` - Compartments
- `vcn://` - Virtual Cloud Networks
- `sub://` - Subnets
- `nsg://` - Network Security Groups
- `vault://` - KMS Vaults
- `drg://` - Dynamic Routing Gateways

Other schemes are available with newer version of FQRN resolver.

## FQRN Parsing and Component Extraction

### Format Structure

All FQRNs follow the pattern: `scheme://compartment_path/resource_name`

**Components:**
1. **Scheme** - Resource type identifier (e.g., `cmp`, `vcn`, `sub`, `nsg`)
2. **Compartment Path** - Hierarchical compartment location (can be nested with `/`)
3. **Resource Name** - The specific resource identifier

### Hierarchical Resources

Some resources are hierarchical and include intermediate path components:

```text
sub://compartment_path/vcn_name/subnet_name
nsg://compartment_path/vcn_name/nsg_name
```

For these resources:
- **Compartment Path** - OCI compartment location
- **VCN Name** - Parent VCN identifier
- **Resource Name** - Subnet or NSG name

### Parsing Method

Use regex to extract components from FQRNs:

#### Simple Resources (Compartment, VCN, Vault)

```hcl
# Pattern: scheme://compartment_path/resource_name
# Extract compartment_path and resource_name

# Example: VCN
vcn_fqrn = "vcn://cmp_prod/cmp_network/vcn_main"

locals {
  vcn_parts        = regex("^vcn://(.+)/([^/]+)$", vcn_fqrn)
  compartment_path = local.vcn_parts[0]  # "cmp_prod/cmp_network"
  vcn_name         = local.vcn_parts[1]  # "vcn_main"
}
```

**Regex Explanation:**
- `^vcn://` - Match scheme literally at start
- `(.+)` - Capture group 1: Everything up to last `/` (compartment path)
- `/` - Match literal `/`
- `([^/]+)$` - Capture group 2: Everything after last `/` until end (resource name)

#### Hierarchical Resources (Subnet, NSG)

```hcl
# Pattern: scheme://compartment_path/vcn_name/resource_name
# Extract compartment_path, vcn_name, and resource_name

# Example: Subnet
subnet_fqrn = "sub://cmp_prod/cmp_network/vcn_main/sub_private"

locals {
  subnet_parts     = regex("^sub://(.+)/([^/]+)/([^/]+)$", subnet_fqrn)
  compartment_path = local.subnet_parts[0]  # "cmp_prod/cmp_network"
  vcn_name         = local.subnet_parts[1]  # "vcn_main"
  subnet_name      = local.subnet_parts[2]  # "sub_private"
}
```

### Deriving Compartment Path from Parent FQRN

**Critical Pattern:** When creating child resources, extract the compartment path from the parent resource FQRN, not from the compartment FQRN variable.

#### Example: Creating Subnet FQRN

```hcl
# WRONG - Using compartment FQRN
locals {
  compartment_name = replace(var.compartment_fqrn, "cmp://", "")  # ❌ Wrong
  subnet_fqrn = "sub://${local.compartment_name}/${local.vcn_name}/..."
}

# CORRECT - Extracting from VCN FQRN
locals {
  # Parse VCN FQRN: vcn://compartment_path/vcn_name
  vcn_fqrn_parts   = regex("^vcn://(.+)/([^/]+)$", var.vcn_fqrn)
  compartment_path = local.vcn_fqrn_parts[0]  # ✅ Correct
  vcn_name         = local.vcn_fqrn_parts[1]

  # Generate subnet FQRN
  subnet_fqrn = "sub://${local.compartment_path}/${local.vcn_name}/${var.subnet_name}"
}
```

**Why this matters:**
- Compartment FQRN: `cmp://cmp_prod/cmp_network` → path is `cmp_prod/cmp_network`
- VCN FQRN: `vcn://cmp_prod/cmp_network/vcn_main` → path is `cmp_prod/cmp_network`
- Subnet FQRN must use: `sub://cmp_prod/cmp_network/vcn_main/subnet_name`

The compartment path in the subnet FQRN must match the compartment path embedded in the VCN FQRN, ensuring consistent hierarchical addressing.

### Parsing Patterns by Resource Type

| Resource Type | Pattern | Regex | Components |
|---------------|---------|-------|------------|
| Compartment | `cmp://path/name` | `^cmp://(.+)/([^/]+)$` | path, name |
| VCN | `vcn://cmp_path/vcn_name` | `^vcn://(.+)/([^/]+)$` | cmp_path, vcn_name |
| Subnet | `sub://cmp_path/vcn/subnet` | `^sub://(.+)/([^/]+)/([^/]+)$` | cmp_path, vcn, subnet |
| NSG | `nsg://cmp_path/vcn/nsg` | `^nsg://(.+)/([^/]+)/([^/]+)$` | cmp_path, vcn, nsg |
| Vault | `vault://cmp_path/vault_name` | `^vault://(.+)/([^/]+)$` | cmp_path, vault_name |

### Implementation Example (Subnet Module)

```hcl
# modules/subnet/main.tf

variable "compartment_fqrn" { type = string }
variable "vcn_fqrn" { type = string }
variable "name" { type = string }

locals {
  # Resolve to OCIDs
  compartment_id = var.fqrn_map[var.compartment_fqrn]
  vcn_id         = var.fqrn_map[var.vcn_fqrn]

  # Parse VCN FQRN to extract compartment path and VCN name
  vcn_fqrn_parts   = regex("^vcn://(.+)/([^/]+)$", var.vcn_fqrn)
  compartment_path = local.vcn_fqrn_parts[0]  # Extract from parent FQRN
  vcn_name         = local.vcn_fqrn_parts[1]
}

resource "oci_core_subnet" "this" {
  compartment_id = local.compartment_id
  vcn_id         = local.vcn_id
  display_name   = var.name
  # ...
}

output "fqrn_map" {
  value = {
    # Construct subnet FQRN using extracted components
    "sub://${local.compartment_path}/${local.vcn_name}/${oci_core_subnet.this.display_name}" = oci_core_subnet.this.id
  }
}
```

## Resolution

FQRNs resolve to OCIDs at Terraform plan/apply time via data source lookups:

```text
FQRN → Compartment Path Module → Data Source Lookup → OCID
```

Uses the existing module: `github.com/rstyczynski/terraform-oci-modules-iam` for compartment path resolution.

## Same-Session Resource Resolution Problem

**Critical Issue:** Data sources execute at the beginning of the plan/apply phase, before resources are created. If a resource is created in the same deployment session, it will not be found by data source lookups.

**Example Problem:**

```hcl
# Creating a subnet in this session
module "subnet" {
  source = "..."
  # creates sub://cmp_prod/cmp_network/vcn_main/sub_new
}

# Trying to reference it immediately - FAILS
module "compute" {
  subnet = "sub://cmp_prod/cmp_network/vcn_main/sub_new"  # Data source won't find it!
}
```

**Solution Pattern (from terraform-oci-modules-iam):**

The `terraform-oci-modules-iam` module implements a **dual-input approach** that separates existing resources from resources to be created:

```hcl
module "terraform-oci-compartments" {
  source = "../terraform-oci-compartments"

  tenancy_id            = local.tenancy_id
  existing_compartments = local.existing_compartments  # List of existing paths
  compartments          = local.compartments           # Map of resources to create
}

locals {
  # Existing compartments - resolved via data sources
  existing_compartments = [
    "/cmp_automation",
    "/cmp_prod/cmp_network"
  ]

  # New compartments - created as resources
  compartments = {
    "/cmp_security" = {
      description   = "security resources"
      enable_delete = true
    },
    "/cmp_security/cmp_siem" = {
      description   = "siem resources"
      enable_delete = true
    }
  }
}
```

**Key Implementation Details:**

1. **Separate Input Variables:**
   - `existing_compartments` - List of compartment paths that already exist (resolved via data sources)
   - `compartments` - Map of compartments to create in this session (created as resources)

2. **Unified Output:**
   - The module merges both existing and newly created resources into a single output map
   - All compartments (existing + new) are accessible via the same interface
   - Output provides OCIDs for both types seamlessly

3. **Resolution Flow:**

   ```text
   For each compartment path:
     IF in existing_compartments list:
       → Use data source to lookup OCID
     ELSE IF in compartments map:
       → Create resource and use resource.id
     Output: Unified map of path → OCID
   ```

**Application to FQRN Resolver:**

The FQRN resolver should follow the same pattern:

- Accept `existing_*` lists for resources that already exist (VCNs, subnets, NSGs, etc.)
- Accept `*` maps for resources to create in this session
- Merge both into unified outputs that provide OCIDs regardless of creation timing
- This allows resources created in the same session to be immediately referenced by other resources

**Example for Subnets:**

```hcl
module "fqrn_resolver" {
  source = "..."
  
  existing_subnets = [
    "sub://cmp_prod/cmp_network/vcn_main/sub_private"  # Already exists
  ]
  
  subnets = {
    "sub://cmp_prod/cmp_network/vcn_main/sub_new" = {
      # Configuration for new subnet
    }
  }
}

# Output provides OCIDs for both existing and new subnets
# module.fqrn_resolver.subnet_ocids["sub://..."] works for both
```

## Aggregating FQRN Maps from Multiple Resource Modules

When a component creates multiple resource types (compartments, VCNs, subnets, NSGs, etc.), each resource module outputs its own FQRN map. These maps need to be aggregated into a single unified FQRN → OCID mapping.

### Resource Module Output Standard

Each resource module must output a consistent `fqrn_map`:

```hcl
# modules/compartment/outputs.tf
output "fqrn_map" {
  description = "FQRN → OCID mapping for compartments"
  value = {
    for k, v in oci_identity_compartment.this :
    "cmp://${v.name}" => v.id
  }
}

# modules/vcn/outputs.tf
output "fqrn_map" {
  description = "FQRN → OCID mapping for VCNs"
  value = {
    for k, v in oci_core_vcn.this :
    "vcn://${var.compartment_path}/${v.display_name}" => v.id
  }
}

# modules/subnet/outputs.tf
output "fqrn_map" {
  description = "FQRN → OCID mapping for subnets"
  value = {
    for k, v in oci_core_subnet.this :
    "sub://${var.compartment_path}/${var.vcn_name}/${v.display_name}" => v.id
  }
}
```

### Dynamic Aggregation Pattern (for_each modules)

When using `for_each` for resource modules, aggregate FQRN maps dynamically:

```hcl
# Component-level main.tf
module "compartments" {
  source   = "..."
  for_each = var.compartments
  # ...
}

module "vcns" {
  source   = "..."
  for_each = var.vcns
  # ...
}

module "subnets" {
  source   = "..."
  for_each = var.subnets
  # ...
}

module "nsgs" {
  source   = "..."
  for_each = var.nsgs
  # ...
}

# Component-level locals.tf
locals {
  # Collect all FQRN maps from each module type
  compartment_fqrns = merge([
    for k, m in module.compartments : m.fqrn_map
  ]...)

  vcn_fqrns = merge([
    for k, m in module.vcns : m.fqrn_map
  ]...)

  subnet_fqrns = merge([
    for k, m in module.subnets : m.fqrn_map
  ]...)

  nsg_fqrns = merge([
    for k, m in module.nsgs : m.fqrn_map
  ]...)
}

# Component-level outputs.tf
output "fqrn_map" {
  description = "Unified FQRN → OCID map from all resource modules"
  value = merge(
    local.compartment_fqrns,
    local.vcn_fqrns,
    local.subnet_fqrns,
    local.nsg_fqrns
  )
}
```

### Benefits of This Pattern

1. **Dynamic Scaling** - Handles variable number of resources per type
2. **Type Safety** - Clear which module types exist in the component
3. **Maintainable** - Easy to add new resource types
4. **Unified Interface** - Single FQRN map output for entire component
5. **Composable** - Component FQRN maps can be further aggregated at higher levels

### Usage Example

```hcl
# Create infrastructure component
module "network_component" {
  source = "..."

  compartments = {
    network = { description = "Network resources" }
    security = { description = "Security resources" }
  }

  vcns = {
    main = { cidr_blocks = ["10.0.0.0/16"] }
  }

  subnets = {
    private = { cidr_block = "10.0.1.0/24" }
    public  = { cidr_block = "10.0.2.0/24" }
  }
}

# Use the unified FQRN map
output "all_resource_ocids" {
  value = module.network_component.fqrn_map
  # Returns:
  # {
  #   "cmp://network" => "ocid1.compartment...."
  #   "cmp://security" => "ocid1.compartment...."
  #   "vcn://cmp_network/main" => "ocid1.vcn...."
  #   "sub://cmp_network/main/private" => "ocid1.subnet...."
  #   "sub://cmp_network/main/public" => "ocid1.subnet...."
  # }
}
```

## Hardcoded Values

To omit resolution for stable resources, it's possible to update a hardcoded map of FQRN to OCID.

## Purpose

- Human-readable resource references
- Avoids hardcoding OCIDs
- Enables declarative configuration in `terraform.tfvars`
- Supports cross-tenancy references (e.g., `drg:acme_tenancy@oc1//...`)

FQRNs are used in the **Zone** domain of the 4-domain model to specify where resources are deployed in OCI.
