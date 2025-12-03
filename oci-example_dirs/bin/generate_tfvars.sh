#!/bin/bash
# Auto-generate terraform.tfvars by concatenating all *.tfvars files
# Excludes terraform.tfvars itself to avoid recursion

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
OUTPUT_FILE="${PROJECT_ROOT}/terraform.tfvars"

# Concatenate all .tfvars files (infra_* and app* patterns, excludes terraform.tfvars)
cd "${PROJECT_ROOT}"
cat $(ls *.tfvars | grep -v terraform.tfvars) > "${OUTPUT_FILE}"

echo "✓ Generated ${OUTPUT_FILE} from separate tfvars files"

