# Auto-Generation Assessment: `terraform_fqrn.tf`

## Executive Summary

**✅ YES, `terraform_fqrn.tf` CAN be auto-generated** using a template engine (Jinja2, Python script, etc.) by extracting module references from main files. The extraction is **reliable** if naming conventions are followed.

## Current Structure Analysis

### 1. Module Patterns Detected

#### Infrastructure Modules (`infra_main.tf`)
```hcl
module "compartments" { ... }      # Single module (not for_each)
module "vcns" { ... }             # for_each module
module "subnets" { ... }          # for_each module
```

**Pattern**: Direct module references, some with `for_each`, some without.

#### App-Specific Modules (`app*_main.tf`)
```hcl
module "app1_nsgs" { ... }                    # Pattern: {app_name}_{resource_type}
module "app1_compute_instances" { ... }       # Pattern: {app_name}_{resource_type}
module "app2_nsgs" { ... }
module "app2_compute_instances" { ... }
```

**Pattern**: `{app_name}_{resource_type}` where:
- `app_name` = extracted from filename (`app1`, `app2`, etc.)
- `resource_type` = `nsgs`, `compute_instances`

### 2. Extraction Rules

#### Rule 1: Shared Modules
- **Source**: `infra_main.tf`
- **Pattern**: `module "{name}"`
- **Detection**: Parse all `module` blocks in `infra_main.tf`
- **Known modules**: `compartments`, `vcns`, `subnets`
- **FQRN map pattern**:
  - Single module: `module.{name}.fqrn_map`
  - for_each module: `merge([for k, m in module.{name} : m.fqrn_map]...)`

#### Rule 2: App Modules
- **Source**: `app*_main.tf` files (glob pattern)
- **Pattern**: `module "{app_name}_{resource_type}"`
- **Detection**: 
  1. Find all `app*_main.tf` files
  2. Extract `app_name` from filename (e.g., `app1_main.tf` → `app1`)
  3. Parse `module` blocks matching pattern `{app_name}_*`
  4. Extract `resource_type` from module name
- **FQRN map pattern**: Always `merge([for k, m in module.{app_name}_{resource_type} : m.fqrn_map]...)`

#### Rule 3: Resource Type Classification
- **NSG modules**: `*_nsgs` → included in `network_fqrns`
- **Compute modules**: `*_compute_instances` → included in unified `fqrns` but not in `network_fqrns`
- **Shared modules**: Always included in all maps

### 3. Auto-Generation Algorithm

```python
# Pseudocode for auto-generation

def extract_modules():
    shared_modules = parse_modules("infra_main.tf")
    app_files = glob("app*_main.tf")
    
    apps = {}
    for app_file in app_files:
        app_name = extract_app_name(app_file)  # "app1" from "app1_main.tf"
        modules = parse_modules(app_file)
        apps[app_name] = {
            'nsgs': f"{app_name}_nsgs" if exists,
            'compute_instances': f"{app_name}_compute_instances" if exists
        }
    
    return {
        'shared': shared_modules,
        'apps': apps
    }

def generate_fqrn_tf(modules):
    # Generate locals for shared modules
    # Generate locals for app modules
    # Generate network_fqrns (shared + all app NSGs)
    # Generate unified fqrns (all modules)
```

## Reliability Assessment

### ✅ Reliable Extraction Points

1. **File Naming Convention**
   - ✅ `infra_main.tf` - fixed name
   - ✅ `app*_main.tf` - consistent pattern
   - ✅ App name extraction: `app(\d+)_main.tf` → `app$1`

2. **Module Naming Convention**
   - ✅ Shared: `compartments`, `vcns`, `subnets` - fixed names
   - ✅ Apps: `{app_name}_{resource_type}` - consistent pattern
   - ✅ Resource types: `nsgs`, `compute_instances` - known set

3. **Module Structure**
   - ✅ All modules output `fqrn_map` (standardized)
   - ✅ for_each modules use merge pattern
   - ✅ Single modules use direct reference

### ⚠️ Potential Issues & Mitigations

1. **Issue**: New resource types added (e.g., `app1_load_balancers`)
   - **Impact**: Template needs update to recognize new type
   - **Mitigation**: 
     - Use configuration file to define resource types
     - Or: Auto-detect by parsing all `module` blocks and inferring types

2. **Issue**: Non-standard module names
   - **Impact**: Extraction fails
   - **Mitigation**: 
     - Enforce naming convention in CI/CD
     - Template validates against expected patterns

3. **Issue**: Module structure changes (e.g., `for_each` added/removed)
   - **Impact**: Wrong FQRN map pattern generated
   - **Mitigation**:
     - Detect `for_each` presence in module block
     - Use appropriate pattern based on detection

4. **Issue**: Shared modules change
   - **Impact**: Need to update template logic
   - **Mitigation**:
     - Auto-detect all modules in `infra_main.tf`
     - Classify as single vs for_each dynamically

## Template Structure (Jinja2 Example)

```jinja2
# terraform_fqrn.tf.j2

locals {
  # Shared infrastructure FQRN maps
  {% for module in shared_modules %}
  {% if module.for_each %}
  {{ module.name }}_fqrns = merge([
    for k, m in module.{{ module.name }} : m.fqrn_map
  ]...)
  {% else %}
  {{ module.name }}_fqrns = module.{{ module.name }}.fqrn_map
  {% endif %}
  {% endfor %}

  # App-specific FQRN maps
  {% for app_name, modules in apps.items() %}
  {% for resource_type, module_name in modules.items() %}
  {{ module_name }}_fqrns = merge([
    for k, m in module.{{ module_name }} : m.fqrn_map
  ]...)
  {% endfor %}
  {% endfor %}

  # Combined FQRN maps for layer dependencies
  compartment_and_vcn_fqrns = merge(
    local.compartment_fqrns,
    local.vcn_fqrns
  )

  compartment_vcn_subnet_fqrns = merge(
    local.compartment_fqrns,
    local.vcn_fqrns,
    local.subnet_fqrns
  )

  # Network FQRNs base (without app NSGs)
  network_fqrns_base = merge(
    local.compartment_fqrns,
    local.vcn_fqrns,
    local.subnet_fqrns
  )

  # Network FQRNs including all NSGs
  network_fqrns = merge(
    local.network_fqrns_base,
    {% for app_name, modules in apps.items() %}
    {% if 'nsgs' in modules %}
    local.{{ modules.nsgs }}_fqrns,
    {% endif %}
    {% endfor %}
  )

  # Unified FQRN map
  fqrns = merge(
    {% for module in shared_modules %}
    local.{{ module.name }}_fqrns,
    {% endfor %}
    {% for app_name, modules in apps.items() %}
    {% for resource_type, module_name in modules.items() %}
    local.{{ module_name }}_fqrns,
    {% endfor %}
    {% endfor %}
  )

  unified_fqrn_map = local.fqrns
}
```

## Implementation Options

### Option 1: Python Script + Jinja2 Template
- **Pros**: Flexible, easy to maintain, good error handling
- **Cons**: Requires Python + Jinja2 dependency
- **Best for**: Complex logic, validation, CI/CD integration

### Option 2: Shell Script + sed/awk
- **Pros**: No external dependencies, simple
- **Cons**: Harder to maintain, limited parsing
- **Best for**: Simple cases, minimal dependencies

### Option 3: Terraform-native (using `templatefile()`)
- **Pros**: No external tools, Terraform-native
- **Cons**: Limited parsing capabilities, complex logic
- **Best for**: Simple templating within Terraform

### Option 4: HCL Parser (e.g., `hclwrite` in Go, `python-hcl2`)
- **Pros**: Proper HCL parsing, reliable extraction
- **Cons**: More complex, language-specific
- **Best for**: Robust parsing, validation

## Recommended Approach

**✅ Use Python + Jinja2** with the following structure:

```
generate_all_fqrn.py          # Main script
  ├── parse_modules.py        # HCL parser for module extraction
  ├── terraform_fqrn.tf.j2   # Jinja2 template (in templates/)
  └── config.yaml            # Resource type definitions (optional)
```

**Extraction Logic**:
1. Parse `infra_main.tf` → extract infrastructure modules
2. Glob `app*_main.tf` → extract app modules
3. Detect `for_each` presence in each module
4. Classify resource types (nsgs, compute_instances, etc.)
5. Generate `terraform_fqrn.tf` from template

**Validation**:
- Check module naming conventions
- Verify `fqrn_map` output exists in modules
- Validate generated HCL syntax

## Conclusion

**✅ Feasible**: Yes, `terraform_fqrn.tf` can be reliably auto-generated.

**✅ Reliable**: Extraction is reliable if naming conventions are followed.

**⚠️ Requirements**:
1. Consistent naming: `app*_main.tf`, `module "{app_name}_{resource_type}"`
2. Standardized module outputs: All modules must output `fqrn_map`
3. Template maintenance: Update template when new resource types are added

**🎯 Recommendation**: Implement Python + Jinja2 solution with validation to ensure reliability.

