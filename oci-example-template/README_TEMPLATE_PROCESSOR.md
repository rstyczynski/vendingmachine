# Terraform Template Processor

## Overview

This directory implements a **Terraform-based template processor** that uses Terraform's `templatefile()` function to generate Terraform files from Jinja2 templates. This approach enables "Terraform to build Terraform" - using infrastructure-as-code patterns to generate infrastructure code itself.

## Concept

Instead of using bash scripts or Python to generate Terraform files, this solution uses pure Terraform:

1. **Templates** (.j2 files) define the structure with variables
2. **Configuration** (template_config.tfvars) specifies what to generate
3. **Terraform** processes templates and writes output files
4. **local_file** resources ensure files are created/updated

## Architecture

### Key Files

- `template_processor.tf` - Main processor logic using templatefile()
- `template_config.tfvars` - Configuration defining what to generate
- `templates/*.j2` - Jinja2 templates for zones and apps
- `terraform_config.tf` - Provider configuration (includes local provider)

### Template Types

#### Zone Templates
Generate infrastructure zone definitions:
- `templates/infra_zone.tf.j2` → `{name}_zone.tf`
- `templates/infra_zone.tfvars.j2` → `{name}_zone.tfvars`
- `templates/infra_zone_custom.tf.j2` → `{name}_zone_custom.tf`

**Template variable:** `{{ name }}`

#### App Compute Templates
Generate application compute instance definitions:
- `templates/app_compute.tf.j2` → `{app_name}_compute.tf`
- `templates/app_compute_custom.tf.j2` → `{app_name}_compute_custom.tf`
- `templates/app_compute_custom.tfvars.j2` → `{app_name}_compute.tfvars`

**Template variable:** `{{ app_name }}`

## Usage

### 1. Configure What to Generate

Edit `template_config.tfvars`:

```hcl
# Generate zone files
zones_to_generate = {
  infra = { name = "infra" }
  app   = { name = "app" }
  db    = { name = "db" }
}

# Generate app files
apps_to_generate = {
  app1 = { app_name = "app1" }
  app2 = { app_name = "app2" }
  web  = { app_name = "web" }
}
```

### 2. Run Template Processor

```bash
# Initialize Terraform (first time only)
terraform init

# Generate files
terraform apply -var-file=template_config.tfvars

# Or auto-approve
terraform apply -var-file=template_config.tfvars -auto-approve
```

### 3. Review Generated Files

Terraform will show:
- What files will be created
- What files will be updated (if templates changed)
- Output showing all generated file paths

### 4. Use Generated Files

The generated files are ready to use in your Terraform configuration:

```bash
# Initialize with generated files
terraform init

# Plan your infrastructure
terraform plan

# Apply your infrastructure
terraform apply
```

## Example Workflow

### Adding a New Zone

1. Edit `template_config.tfvars`:
   ```hcl
   zones_to_generate = {
     infra = { name = "infra" }
     prod  = { name = "prod" }  # NEW
   }
   ```

2. Generate:
   ```bash
   terraform apply -var-file=template_config.tfvars -auto-approve
   ```

3. Files created:
   - `prod_zone.tf`
   - `prod_zone.tfvars`
   - `prod_zone_custom.tf`

### Adding a New App

1. Edit `template_config.tfvars`:
   ```hcl
   apps_to_generate = {
     app1    = { app_name = "app1" }
     jenkins = { app_name = "jenkins" }  # NEW
   }
   ```

2. Generate:
   ```bash
   terraform apply -var-file=template_config.tfvars -auto-approve
   ```

3. Files created:
   - `jenkins_compute.tf`
   - `jenkins_compute_custom.tf`
   - `jenkins_compute.tfvars`

## How It Works

### Template Processing Flow

```
template_config.tfvars
         ↓
   (Terraform reads)
         ↓
  variables defined
         ↓
   locals compute
    (templatefile())
         ↓
  local_file resources
         ↓
   Files written to disk
```

### templatefile() Function

Terraform's `templatefile()` processes Jinja2 templates:

```hcl
locals {
  zone_files = {
    for zone_key, zone in var.zones_to_generate : zone_key => {
      tf_content = templatefile("${path.module}/templates/infra_zone.tf.j2", {
        name = zone.name
      })
      tf_filename = "${path.module}/${zone.name}_zone.tf"
    }
  }
}
```

### File Writing

The `local_file` resource writes files:

```hcl
resource "local_file" "zone_tf" {
  for_each = local.zone_files

  filename = each.value.tf_filename
  content  = each.value.tf_content

  file_permission = "0644"
}
```

## Benefits

### Pure Terraform Solution
- No external scripts needed (bash, Python)
- Uses native Terraform functions
- Infrastructure-as-code for code generation
- Declarative configuration

### Idempotent
- Only updates changed files
- Terraform state tracks files
- Safe to re-run

### Trackable
- Terraform plan shows what will change
- Git-friendly workflow
- State management included

### Extensible
- Easy to add new template types
- Simple variable structure
- Template inheritance possible

## Advanced Usage

### Custom Templates

Create new template types by:

1. Adding templates to `templates/` directory
2. Adding local processing logic in `template_processor.tf`
3. Adding file resources
4. Adding configuration in `template_config.tfvars`

Example:

```hcl
# In template_processor.tf
locals {
  custom_files = {
    for item_key, item in var.custom_to_generate : item_key => {
      content = templatefile("${path.module}/templates/custom.tf.j2", {
        custom_var = item.custom_var
      })
      filename = "${path.module}/${item.name}_custom.tf"
    }
  }
}

resource "local_file" "custom" {
  for_each = local.custom_files
  filename = each.value.filename
  content  = each.value.content
  file_permission = "0644"
}
```

### Selective Generation

Generate only specific types:

```bash
# Only zones
terraform apply -var-file=template_config.tfvars \
  -var='apps_to_generate={}'

# Only apps
terraform apply -var-file=template_config.tfvars \
  -var='zones_to_generate={}'
```

### Clean Up Generated Files

To remove generated files:

```bash
terraform destroy -var-file=template_config.tfvars -auto-approve
```

This removes all files managed by the template processor.

## Comparison to Script-Based Generation

### Template Processor (This Solution)
- Pure Terraform, no external dependencies
- Declarative configuration
- State-managed file tracking
- Idempotent by design
- Shows plan before changes

### Script-Based (Alternative)
- Requires bash/Python
- Imperative logic
- Manual file tracking
- May need custom idempotency
- No preview of changes

## Limitations

### Terraform Constraints
- Cannot use dynamically created templates (templates must exist before Terraform runs)
- File paths must be known at plan time
- Limited string manipulation compared to full scripting languages

### When to Use Scripts Instead
- Need to fetch template content from API
- Complex conditional logic beyond Terraform's capabilities
- Integration with external systems
- Dynamic template discovery

## Integration with OCI Vending Machine

This template processor integrates with the OCI Vending Machine framework:

1. **Generate zone definitions** for different environments
2. **Generate app compute instances** for multiple applications
3. **Maintain consistency** across generated files
4. **Support FQRN pattern** in generated templates

See main project documentation for the full vending machine architecture.

## Troubleshooting

### Template Not Found Error
```
Error: no file exists at "./templates/xyz.j2"
```
**Solution:** Check template exists and path is correct in template_processor.tf

### Variables Not Substituted
Templates showing `{{ name }}` instead of actual values.

**Solution:** Verify variable name matches template expectations (e.g., `name` vs `app_name`)

### Files Not Created
**Solution:**
1. Check terraform state: `terraform state list`
2. Run with debug: `TF_LOG=DEBUG terraform apply`
3. Verify file permissions

### Syntax Errors in Generated Files
**Solution:**
1. Check template syntax in .j2 files
2. Test template variables match configuration
3. Validate generated files: `terraform validate`

## Next Steps

1. Add more template types as needed
2. Create templates for other resources (databases, load balancers)
3. Integrate with CI/CD pipeline
4. Add validation for generated files

## References

- [Terraform templatefile() function](https://www.terraform.io/language/functions/templatefile)
- [Terraform local_file resource](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file)
- [Jinja2 template syntax](https://jinja.palletsprojects.com/)
- OCI Vending Machine main documentation
