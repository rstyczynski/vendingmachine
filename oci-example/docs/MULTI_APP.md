# Multi-Application Infrastructure Configuration Guide

This guide explains how to manage multiple applications with a clean separation between shared infrastructure and application-specific resources.

## Overview

In a multi-application setup:
- **Shared Resources**: VCN, Subnet, Compartment (created once, shared by all apps)
- **App-Specific Resources**: NSGs, Compute Instances (each app has its own)

## File Structure

```
oci-example/
├── infra_*.tf                 # Infrastructure files (static, operator-maintained)
│   ├── infra_locals.tf        # Infrastructure locals (tenancy, region, availability domains)
│   ├── infra_main.tf          # Infrastructure (compartments, VCNs, subnets)
│   ├── infra_outputs.tf       # Infrastructure outputs
│   ├── infra_variables.tf     # Infrastructure variable definitions
│   └── infra_terraform.tfvars # Infrastructure variable values
├── terraform_*.tf             # Auto-generated files (DO NOT EDIT)
│   └── terraform_fqrn.tf      # Unified FQRN map aggregation (auto-generated)
│
├── app1_*.tf                 # APP1-specific files
│   ├── app1_main.tf          # APP1 infrastructure (NSGs, compute instances)
│   ├── app1_variables.tf     # APP1 variable definitions
│   ├── app1_terraform.tfvars # APP1 variable values
│   └── app1_outputs.tf       # APP1 outputs
│
├── app2_*.tf                 # APP2-specific files
│   ├── app2_main.tf          # APP2 infrastructure (NSGs, compute instances)
│   ├── app2_variables.tf     # APP2 variable definitions
│   ├── app2_terraform.tfvars # APP2 variable values
│   └── app2_outputs.tf       # APP2 outputs
│
├── terraform.tfvars          # Auto-generated: combines shared + app1 + app2
└── generate_terraform_tfvars.sh # Script to auto-generate terraform.tfvars
```

## 1. Variable Management

### Auto-Generated `terraform.tfvars`

The `terraform.tfvars` file is **auto-generated** by concatenating:
- `infra_terraform.tfvars` (infrastructure)
- `app1_terraform.tfvars` (APP1 configuration)
- `app2_terraform.tfvars` (APP2 configuration)

### Generating terraform.tfvars

Run the generation script:

```bash
./generate_terraform_tfvars.sh
```

This creates `terraform.tfvars` from the separate files. Terraform automatically loads `terraform.tfvars` but **NOT** other `.tfvars` files unless explicitly specified with `-var-file`.

```hcl
# terraform.tfvars

# Main application variables
compute_instances = {
  "instance://vm_demo/demo/demo_instance" = {
    # ... main app config
  }
}

# APP2 application variables
app2_compute_instances = {
  "instance://vm_demo/demo/app2_instance" = {
    # ... app2 config
  }
}

app2_nsgs = {
  "nsg://vm_demo/demo/demo_vcn/app2_web" = {
    # ... app2 NSG config
  }
}
```

### Manual Approach (Alternative)

If you prefer to load separate files manually:

```bash
terraform apply \
  -var-file=infra_terraform.tfvars \
  -var-file=app1_terraform.tfvars \
  -var-file=app2_terraform.tfvars
```

**Note**: The auto-generation script is recommended for simplicity.

## 2. FQRN Map Integration

### Unified FQRN Map Structure

The `terraform_fqrn.tf` file aggregates FQRN maps from all applications:

```hcl
# terraform_fqrn.tf

locals {
  # Shared infrastructure FQRN maps
  compartment_fqrns = module.compartments.fqrn_map
  vcn_fqrns = merge([for k, m in module.vcns : m.fqrn_map]...)
  subnet_fqrns = merge([for k, m in module.subnets : m.fqrn_map]...)

  # APP1 application FQRN maps
  app1_nsg_fqrns = merge([for k, m in module.app1_nsgs : m.fqrn_map]...)
  app1_compute_instance_fqrns = merge([for k, m in module.app1_compute_instances : m.fqrn_map]...)

  # APP2 application FQRN maps
  app2_nsg_fqrns = merge([for k, m in module.app2_nsgs : m.fqrn_map]...)
  app2_compute_instance_fqrns = merge([for k, m in module.app2_compute_instances : m.fqrn_map]...)

  # Unified FQRN map - includes ALL resources from all applications
  fqrns = merge(
    local.compartment_fqrns,
    local.vcn_fqrns,
    local.subnet_fqrns,
    local.app1_nsg_fqrns,              # APP1 NSGs
    local.app1_compute_instance_fqrns,  # APP1 compute instances
    local.app2_nsg_fqrns,              # APP2 NSGs
    local.app2_compute_instance_fqrns  # APP2 compute instances
  )

  # Network FQRNs (for resource dependencies)
  # Base network (without app NSGs to avoid cycles during NSG creation)
  network_fqrns_base = merge(
    local.compartment_fqrns,
    local.vcn_fqrns,
    local.subnet_fqrns
  )

  # Full network FQRNs (includes all app NSGs after they're created)
  network_fqrns = merge(
    local.network_fqrns_base,
    local.app1_nsg_fqrns,  # APP1 NSGs available to all resources
    local.app2_nsg_fqrns   # APP2 NSGs available to all resources
  )
}
```

### Key Points:

1. **Unified Map**: `local.fqrns` contains ALL resources from all applications
2. **Network Map**: `local.network_fqrns` includes all NSGs (main + app2) for cross-app references
3. **Cycle Prevention**: Use `network_fqrns_base` when creating APP2 NSGs to avoid dependency cycles

## 3. Sharing Infrastructure Resources

### Shared VCN and Subnet

All applications reference the same VCN and subnet from `infra_main.tf`:

```hcl
# app1_main.tf or app2_main.tf

module "app1_compute_instances" {
  # ...
  zone = {
    subnet = var.app1_zones[each.value.zone].subnet  # References shared subnet FQRN
    ad     = var.app1_zones[each.value.zone].ad
  }
  fqrn_map = local.network_fqrns  # Includes shared VCN/subnet from terraform_fqrn.tf
}
```

The shared subnet FQRN is resolved from `local.network_fqrns` which includes all shared infrastructure.

### Shared Compartment

Both applications use the same compartment (defined in main `terraform.tfvars`):

```hcl
compartments = {
  "cmp://vm_demo/demo" = {
    description   = "Shared compartment for all applications"
    enable_delete = true
  }
}
```

## 4. Cross-Application Resource References

### Cross-Application NSG References

Applications can reference each other's NSGs:

```hcl
# app1_terraform.tfvars

app1_compute_instances = {
  "instance://vm_demo/demo/demo_instance" = {
    zone = "zone://vm_demo/demo/app"
    nsg  = [
      "nsg://vm_demo/demo/demo_vcn/ssh",           # APP1 NSG
      "nsg://vm_demo/demo/demo_vcn/app2_web"       # APP2 NSG (cross-reference)
    ]
  }
}
```

This works because:
1. All app NSGs are included in `local.network_fqrns` (from `terraform_fqrn.tf`)
2. All compute instances receive `local.network_fqrns` as their `fqrn_map`
3. FQRN resolution finds NSG OCIDs from any application

### Referencing APP1 NSGs from APP2

APP2 compute instances can reference APP1 NSGs:

```hcl
# app2_terraform.tfvars

app2_compute_instances = {
  "instance://vm_demo/demo/app2_instance" = {
    zone = "zone://vm_demo/demo/app2"
    nsg  = [
      "nsg://vm_demo/demo/demo_vcn/app2_web",      # APP2 NSG
      "nsg://vm_demo/demo/demo_vcn/ssh"            # APP1 NSG (cross-reference)
    ]
  }
}
```

## 5. Dependency Management

### Module Dependencies

Ensure proper dependency ordering:

```hcl
# app1_main.tf or app2_main.tf

module "app1_nsgs" {
  # ...
  fqrn_map = local.compartment_vcn_subnet_fqrns  # Use base (excludes app NSGs) to avoid cycle
  depends_on = [module.subnets]
}

module "app1_compute_instances" {
  # ...
  fqrn_map = local.network_fqrns  # Use full network map (includes all app NSGs)
  depends_on = [
    module.subnets,
    module.app1_nsgs  # Wait for APP1 NSGs to be created
  ]
}
```

### Cycle Prevention

**Problem**: If `network_fqrns` includes app NSGs, and app NSG modules use `network_fqrns`, you get a cycle.

**Solution**: 
- Use `compartment_vcn_subnet_fqrns` or `network_fqrns_base` when creating app NSGs (excludes app NSGs)
- Use `network_fqrns` (which includes all app NSGs) for compute instances

## 6. Outputs

### Output File Structure

Outputs are split into shared and app-specific files:

```hcl
# infra_outputs.tf - Infrastructure outputs
output "fqrn_map" {
  description = "Unified FQRN → OCID map from all applications"
  value = local.fqrns  # Includes all resources from all apps
}

output "compartments" { ... }
output "vcns" { ... }
output "subnets" { ... }

# app1_outputs.tf - APP1-specific outputs
output "app1_nsgs" { ... }
output "app1_compute_instances" { ... }

# app2_outputs.tf - APP2-specific outputs
output "app2_nsgs" { ... }
output "app2_compute_instances" { ... }
```

## 7. Adding a New Application (APP3)

### Step 1: Create APP3 Files

Create the following files following the same pattern as APP1/APP2:
- `app3_main.tf` - APP3 infrastructure
- `app3_variables.tf` - APP3 variable definitions
- `app3_terraform.tfvars` - APP3 configuration
- `app3_outputs.tf` - APP3 outputs

### Step 2: Regenerate `terraform_fqrn.tf`

Run the generation script to automatically include APP3:

```bash
./bin/generate_all_fqrn.sh
```

Or manually update `terraform_fqrn.tf` (not recommended):

```hcl
# terraform_fqrn.tf

locals {
  # ... existing maps ...

  # APP3 module FQRN maps
  app3_nsg_fqrns = merge([
    for k, m in module.app3_nsgs : m.fqrn_map
  ]...)

  app3_compute_instance_fqrns = merge([
    for k, m in module.app3_compute_instances : m.fqrn_map
  ]...)

  # Update unified map
  fqrns = merge(
    # ... existing maps ...
    local.app3_nsg_fqrns,
    local.app3_compute_instance_fqrns
  )

  # Update network map
  network_fqrns = merge(
    local.network_fqrns_base,
    local.app1_nsg_fqrns,
    local.app2_nsg_fqrns,
    local.app3_nsg_fqrns  # Add APP3 NSGs
  )
}
```

### Step 3: Update Generation Script

Update `generate_terraform_tfvars.sh` to include APP3:

```bash
cat "${SCRIPT_DIR}/app3_terraform.tfvars" >> "${OUTPUT_FILE}"
```

### Step 4: Regenerate terraform.tfvars

```bash
./generate_terraform_tfvars.sh
```

## 8. Best Practices

### ✅ DO:

1. **Use auto-generation script** to create `terraform.tfvars` from separate files
2. **Keep app-specific configs in separate files** (`app1_terraform.tfvars`, `app2_terraform.tfvars`)
3. **Keep infrastructure configs in `infra_terraform.tfvars`**
4. **Use FQRNs consistently** for all resource references
5. **Include all app resources in unified `fqrns` map** (in `terraform_fqrn.tf`) for cross-references
6. **Use `network_fqrns_base`** when creating NSGs to avoid cycles
7. **Use `network_fqrns`** (with all NSGs) for compute instances
8. **Regenerate `terraform_fqrn.tf`** when adding new applications (run `./bin/generate_all_fqrn.sh`)
9. **Regenerate `terraform.tfvars`** after modifying separate tfvars files

### ❌ DON'T:

1. **Don't manually edit `terraform.tfvars`** - it's auto-generated
2. **Don't create duplicate VCNs/subnets** - share them via `infra_main.tf`
3. **Don't include app NSGs in `network_fqrns` when creating app NSGs** - causes cycles
4. **Don't hardcode OCIDs** - always use FQRN resolution
5. **Don't forget to regenerate `terraform_fqrn.tf`** when adding new applications (run `./bin/generate_all_fqrn.sh`)
6. **Don't mix shared and app-specific resources** in the same file

## 9. Troubleshooting

### Error: "Invalid index" when referencing NSG

**Cause**: NSG FQRN not found in `fqrn_map`

**Solution**: 
- Ensure APP2 NSGs are included in `local.network_fqrns`
- Verify the NSG FQRN matches exactly (case-sensitive)
- Check that `network_fqrns` is passed to compute instances

### Error: "Cycle detected"

**Cause**: Circular dependency in FQRN maps

**Solution**:
- Use `network_fqrns_base` when creating NSGs
- Use `network_fqrns` (with NSGs) for compute instances
- Ensure proper `depends_on` declarations

### Error: "No changes" when expecting resources

**Cause**: Variables not loaded - `terraform.tfvars` not regenerated

**Solution**:
- Run `./generate_terraform_tfvars.sh` to regenerate `terraform.tfvars` from separate files

## 10. Example: Complete Multi-App Setup

See the current configuration:

**Infrastructure** (`infra_*.tf`):
- `infra_locals.tf` - Tenancy, region, availability domains
- `infra_main.tf` - Compartments, VCNs, subnets
- `infra_outputs.tf` - Infrastructure outputs
- `infra_variables.tf` - Infrastructure variable definitions
- `infra_terraform.tfvars` - Infrastructure configuration

**Auto-Generated** (`terraform_*.tf`):
- `terraform_fqrn.tf` - Unified FQRN map aggregation (auto-generated)
- `infra_outputs.tf` - Infrastructure outputs

**APP1** (`app1_*.tf`):
- `app1_main.tf` - APP1 NSGs and compute instances
- `app1_variables.tf` - APP1 variable definitions
- `app1_terraform.tfvars` - APP1 configuration
- `app1_outputs.tf` - APP1 outputs

**APP2** (`app2_*.tf`):
- `app2_main.tf` - APP2 NSGs and compute instances
- `app2_variables.tf` - APP2 variable definitions
- `app2_terraform.tfvars` - APP2 configuration
- `app2_outputs.tf` - APP2 outputs

**Auto-Generated**:
- `terraform.tfvars` - Combined from shared + app1 + app2 (via `generate_terraform_tfvars.sh`)

All applications share:
- Compartment: `cmp:///vm_demo/demo` (from `infra_main.tf`)
- VCN: `vcn://vm_demo/demo/demo_vcn` (from `infra_main.tf`)
- Subnet: `sub://vm_demo/demo/demo_vcn/public_subnet` (from `infra_main.tf`)

Each application has:
- Its own NSGs (can reference each other via FQRN)
- Its own compute instances (can use any NSG via FQRN)

