# Auto-Generation Scripts

## Overview

Two files are auto-generated to simplify multi-application management:

1. **`terraform.tfvars`** - Combined from separate tfvars files
2. **`terraform_fqrn.tf`** - FQRN map aggregation from module references

## Scripts

### `bin/generate.sh` ⭐ **RECOMMENDED**
- **Purpose**: Generate all auto-generated files (runs both scripts below)
- **Usage**: `./bin/generate.sh`
- **What it does**: Runs both `generate_terraform_tfvars.sh` and `generate_all_fqrn.sh`
- **Use this**: When you want to regenerate everything after adding new apps

### `bin/generate_terraform_tfvars.sh`
- **Purpose**: Concatenate all `*_terraform.tfvars` files into `terraform.tfvars`
- **Usage**: `./bin/generate_terraform_tfvars.sh`
- **Dependencies**: None (pure bash)
- **Auto-detects**: All `infra_*_terraform.tfvars` and `app*_terraform.tfvars` files

### `bin/generate_all_fqrn.sh`
- **Purpose**: Generate `terraform_fqrn.tf` from module references using Jinja2 template
- **Usage**: `./bin/generate_all_fqrn.sh`
- **Dependencies**: Python 3, jinja2 (auto-installed in `.venv/`)
- **Auto-detects**: Modules from `infra_main.tf` and `app*_main.tf` files
- **Template**: `templates/terraform_fqrn.tf.j2`

## Workflow

### When Adding a New Application:

1. Create app files:
   - `app3_main.tf`
   - `app3_variables.tf`
   - `app3_terraform.tfvars`
   - `app3_outputs.tf`

2. Run generation script:
   ```bash
   ./bin/generate.sh  # Regenerates both terraform.tfvars and terraform_fqrn.tf with APP3
   ```
   
   Or run individually:
   ```bash
   ./bin/generate_terraform_tfvars.sh  # Regenerates terraform.tfvars
   ./bin/generate_all_fqrn.sh          # Regenerates terraform_fqrn.tf
   ```

3. Validate:
   ```bash
   terraform validate
   ```

That's it! No manual file editing needed.

## Virtual Environment

The `generate_all_fqrn.sh` script automatically:
- Creates `.venv/` if it doesn't exist
- Installs jinja2 if needed
- Uses the venv for generation

The `.venv/` directory is git-ignored and should not be committed.
