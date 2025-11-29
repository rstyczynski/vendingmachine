#!/bin/bash
# Generate all auto-generated files
# Runs both terraform.tfvars and all_fqrn.tf generation scripts

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "═══════════════════════════════════════════════════════════════"
echo "Generating all auto-generated files..."
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Generate terraform.tfvars
echo "1. Generating terraform.tfvars..."
cd "${PROJECT_ROOT}"
"${SCRIPT_DIR}/generate_tfvars.sh"
echo ""

# Generate terraform_fqrn.tf
echo "2. Generating terraform_fqrn.tf..."
cd "${PROJECT_ROOT}"
"${SCRIPT_DIR}/generate_fqrn.sh"
echo ""

echo "═══════════════════════════════════════════════════════════════"
echo "✓ All files generated successfully!"
echo "═══════════════════════════════════════════════════════════════"

