#!/bin/bash
# Add compute resources to an application
# Usage: ./bin/add_compute.sh <app_name>
# Example: ./bin/add_compute.sh app3

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Check if app name is provided
if [ -z "$1" ]; then
    echo "Error: App name is required"
    echo "Usage: $0 <app_name>"
    echo "Example: $0 app3"
    exit 1
fi

APP_NAME="$1"

# Validate app name format (should be lowercase, alphanumeric with underscores)
if ! [[ "$APP_NAME" =~ ^[a-z][a-z0-9_]*$ ]]; then
    echo "Error: App name must be lowercase, start with a letter, and contain only letters, numbers, and underscores"
    echo "Example: app3, my_app, app_1"
    exit 1
fi

# Check if compute files already exist
TF_FILE="${PROJECT_ROOT}/${APP_NAME}_compute.tf"
TFVARS_FILE="${PROJECT_ROOT}/${APP_NAME}_compute.tfvars"

if [ -f "$TF_FILE" ] || [ -f "$TFVARS_FILE" ]; then
    echo "Error: Compute files already exist for ${APP_NAME}:"
    [ -f "$TF_FILE" ] && echo "  - ${TF_FILE}"
    [ -f "$TFVARS_FILE" ] && echo "  - ${TFVARS_FILE}"
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
echo "Adding compute resources for ${APP_NAME}..."
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Generate .tf file
echo "1. Generating ${APP_NAME}_compute.tf..."
python3 <<EOF
from jinja2 import Template
from pathlib import Path

template_path = Path("${SCRIPT_DIR}/../templates/app_compute.tf.j2")
output_path = Path("${TF_FILE}")

template = Template(template_path.read_text())
output_path.write_text(template.render(app_name="${APP_NAME}"))
print(f"✓ Created {output_path}")
EOF

# Generate .tfvars file
echo "2. Generating ${APP_NAME}_compute.tfvars..."
python3 <<EOF
from jinja2 import Template
from pathlib import Path

template_path = Path("${SCRIPT_DIR}/../templates/app_compute.tfvars.j2")
output_path = Path("${TFVARS_FILE}")

template = Template(template_path.read_text())
output_path.write_text(template.render(app_name="${APP_NAME}"))
print(f"✓ Created {output_path}")
EOF

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "✓ Compute resources added successfully for ${APP_NAME}!"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Next steps:"
echo "  1. Review and customize ${APP_NAME}_compute.tfvars"
echo "  2. Ensure the zone 'zone://vm_demo/demo/${APP_NAME}' exists in infra.tfvars"
echo "  3. Run 'terraform validate' to verify the configuration"
echo ""

