# FQRN aggregatioon

The `bin/generate_fqrn.sh` script generates `terraform_fqrn.tf` which aggregates all FQRN maps.

### How it works

1. `bin/generate_fqrn.py` extracts module names from `infra_*.tf` and `{app}_*.tf` files
2. `templates/terraform_fqrn.tf.j2` renders the aggregation logic using Jinja2
3. Output is `terraform_fqrn.tf` with all `local.*_fqrns` variables

### When to update the template

Update `templates/terraform_fqrn.tf.j2` when:

1. **Adding new infrastructure module types** (like zones, bastions)
   - Add detection: `{%- set new_mod = shared_modules | selectattr("name", "equalto", "new_modules") | first %}`
   - Add to appropriate combined maps (e.g., `infra_fqrns`)

2. **New combined FQRN maps needed**
   - Create new `merge()` blocks combining required module FQRNs
   - Use dynamic detection, NOT hardcoded module names

### Key combined maps

| Map | Contains | Used by |
|-----|----------|---------|
| `network_fqrns_base` | compartments, vcns, subnets | NSG creation (avoids cycles) |
| `network_fqrns` | network_fqrns_base + NSGs | Compute instances |
| `infra_fqrns` | network + bastions + NSGs | Zones |
| `fqrns` | ALL resources | Output, general use |

### Regenerate after changes

```bash
./bin/generate_fqrn.sh
terraform fmt terraform_fqrn.tf
terraform validate
```
