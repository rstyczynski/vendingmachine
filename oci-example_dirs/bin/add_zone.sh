#!/bin/bash
# Add zone resources with a custom prefix
# Usage: ./bin/add_zone.sh <name>
# Example: ./bin/add_zone.sh app1
#
# This generates:
#   - <name>_zone.tf        (zone module instantiation)
#   - <name>_zone.tfvars    (zone configuration)
#   - <name>_zone_custom.tf (custom var2hcl override - optional)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Activate virtual environment if it exists
if [ -f "${PROJECT_ROOT}/.venv/bin/activate" ]; then
    source "${PROJECT_ROOT}/.venv/bin/activate"
fi

# Check if name is provided
if [ -z "$1" ]; then
    echo "Error: Name is required"
    echo "Usage: $0 <name>"
    echo "Example: $0 app1"
    echo ""
    echo "This will generate:"
    echo "  - <name>_zone.tf"
    echo "  - <name>_zone.tfvars"
    echo "  - <name>_zone_custom.tf"
    exit 1
fi

NAME="$1"

# Validate name format (should be lowercase, alphanumeric with underscores)
if ! [[ "$NAME" =~ ^[a-z][a-z0-9_]*$ ]]; then
    echo "Error: Name must be lowercase, start with a letter, and contain only letters, numbers, and underscores"
    echo "Example: app1, my_zone, infra"
    exit 1
fi

# Check if zone files already exist
TF_FILE="${PROJECT_ROOT}/${NAME}_zone.tf"
TFVARS_FILE="${PROJECT_ROOT}/${NAME}_zone.tfvars"
CUSTOM_FILE="${PROJECT_ROOT}/${NAME}_zone_custom.tf"

if [ -f "$TF_FILE" ] || [ -f "$TFVARS_FILE" ] || [ -f "$CUSTOM_FILE" ]; then
    echo "Error: Zone files already exist for ${NAME}:"
    [ -f "$TF_FILE" ] && echo "  - ${TF_FILE}"
    [ -f "$TFVARS_FILE" ] && echo "  - ${TFVARS_FILE}"
    [ -f "$CUSTOM_FILE" ] && echo "  - ${CUSTOM_FILE}"
    echo ""
    echo "To regenerate, delete these files first."
    exit 1
fi

# Check if Jinja2 is available
if ! python3 -c "import jinja2" 2>/dev/null; then
    echo "Error: jinja2 is required but not installed"
    echo "Install it with: pip install jinja2"
    exit 1
fi

echo "═══════════════════════════════════════════════════════════════"
echo "Adding zone resources for ${NAME}..."
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Generate .tf file
echo "1. Generating ${NAME}_zone.tf..."
python3 <<EOF
from jinja2 import Template
from pathlib import Path

template_path = Path("${SCRIPT_DIR}/../templates/infra_zone.tf.j2")
output_path = Path("${TF_FILE}")

template = Template(template_path.read_text())
output_path.write_text(template.render(name="${NAME}"))
print(f"✓ Created {output_path}")
EOF

# Generate .tfvars file
echo "2. Generating ${NAME}_zone.tfvars..."
python3 <<EOF
from jinja2 import Template
from pathlib import Path

template_path = Path("${SCRIPT_DIR}/../templates/infra_zone.tfvars.j2")
output_path = Path("${TFVARS_FILE}")

template = Template(template_path.read_text())
output_path.write_text(template.render(name="${NAME}"))
print(f"✓ Created {output_path}")
EOF

# Generate custom var2hcl file
echo "3. Generating ${NAME}_zone_custom.tf..."
python3 <<EOF
from jinja2 import Template
from pathlib import Path

template_path = Path("${SCRIPT_DIR}/../templates/infra_zone_custom.tf.j2")
output_path = Path("${CUSTOM_FILE}")

template = Template(template_path.read_text())
output_path.write_text(template.render(name="${NAME}"))
print(f"✓ Created {output_path}")
EOF

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "✓ Zone resources added successfully for ${NAME}!"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Next steps:"
echo "  1. Review and customize ${NAME}_zone.tfvars with your zones"
echo "  2. Ensure referenced subnets exist (e.g., sub://vm_demo/demo/demo_vcn/subnet)"
echo "  3. Ensure referenced bastions exist (e.g., bastion://vm_demo/demo/demo_bastion)"
echo "  4. (Optional) Customize ${NAME}_zone_custom.tf to override var2hcl logic"
echo "  5. Run 'terraform validate' to verify the configuration"
echo ""
