# Custom Variable Proxy (var2hcl) Pattern

## Overview

The variable proxy pattern allows users to customize the transformation logic from variables to locals. Each resource type supports both **default** and **custom** var2hcl logic.

## Pattern Structure

### Default var2hcl File

Every resource has a `*_var2hcl.tf` file that contains:
1. **Default transformation logic** (`*_var2hcl_default`)
2. **Custom override check** (`*_var2hcl_custom_override`)
3. **Final var2hcl** that uses custom if provided, otherwise default

Example: `web2_compute_var2hcl.tf`
```hcl
locals {
  # Default logic
  web2_compute_instances_var2hcl_default = { ... }
  
  # Custom override (optional)
  web2_compute_instances_var2hcl_custom_override = try(
    local.web2_compute_instances_var2hcl_custom_override,
    {}
  )
  
  # Final: use custom if provided, else default
  web2_compute_instances_var2hcl = length(local.web2_compute_instances_var2hcl_custom_override) > 0 ? 
    local.web2_compute_instances_var2hcl_custom_override : 
    local.web2_compute_instances_var2hcl_default
}
```

### Custom var2hcl File (Optional)

Users can create `*_var2hcl_custom.tf` to override the default logic:

1. Copy the example file: `cp web2_compute_var2hcl_custom.tf.example web2_compute_var2hcl_custom.tf`
2. Customize the transformation logic
3. Define `*_var2hcl_custom_override` local

Example: `web2_compute_var2hcl_custom.tf`
```hcl
locals {
  web2_compute_instances_var2hcl_custom_override = {
    for k, v in var.web2_compute_instances : k => {
      instance_fqrn = k
      zone          = local.zones_var2hcl[v.zone].subnet
      availability_domain = local.zones_var2hcl[v.zone].ad
      nsg          = v.nsg
      spec         = merge(v.spec, {
        enable_bastion_plugin = true  # Custom: force enable for all
      })
    }
  }
}
```

## How It Works

1. **Default behavior**: If no custom file exists, `*_var2hcl_custom_override` is an empty map `{}`, so the default logic is used
2. **Custom override**: If custom file exists and defines `*_var2hcl_custom_override`, it completely replaces the default
3. **Final var2hcl**: The module uses `*_var2hcl` which automatically selects custom or default

## Benefits

- **Non-breaking**: Default logic always works
- **Flexible**: Users can customize without modifying generated files
- **Clear separation**: Custom logic is in separate files
- **Version control friendly**: Custom files can be gitignored if needed

## Usage Examples

### Example 1: Force enable bastion plugin for all instances
```hcl
# web2_compute_var2hcl_custom.tf
locals {
  web2_compute_instances_var2hcl_custom_override = {
    for k, v in var.web2_compute_instances : k => {
      instance_fqrn = k
      zone          = local.zones_var2hcl[v.zone].subnet
      availability_domain = local.zones_var2hcl[v.zone].ad
      nsg          = v.nsg
      spec         = merge(v.spec, {
        enable_bastion_plugin = true
      })
    }
  }
}
```

### Example 2: Add default tags to all instances
```hcl
locals {
  web2_compute_instances_var2hcl_custom_override = {
    for k, v in var.web2_compute_instances : k => {
      instance_fqrn = k
      zone          = local.zones_var2hcl[v.zone].subnet
      availability_domain = local.zones_var2hcl[v.zone].ad
      nsg          = v.nsg
      spec         = merge(v.spec, {
        freeform_tags = merge(
          try(v.spec.freeform_tags, {}),
          {
            "custom_tag" = "custom_value"
            "environment" = "production"
          }
        )
      })
    }
  }
}
```

## File Naming Convention

- Default: `{resource}_var2hcl.tf` (auto-generated)
- Custom: `{resource}_var2hcl_custom.tf` (user-created)
- Example: `web2_compute_var2hcl_custom.tf.example` (template)

