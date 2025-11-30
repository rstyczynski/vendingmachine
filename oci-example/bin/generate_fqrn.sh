#!/bin/bash
# Generate terraform_fqrn.tf using Python for data extraction and Jinja2 CLI for template rendering

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
VENV_DIR="${PROJECT_ROOT}/.venv"
PYTHON="${VENV_DIR}/bin/python"
TMP_DIR="${PROJECT_ROOT}/tmp"
YAML_DATA="${TMP_DIR}/terraform_fqrn_data.yaml"
TEMPLATE="${PROJECT_ROOT}/templates/terraform_fqrn.tf.j2"
OUTPUT="${PROJECT_ROOT}/terraform_fqrn.tf"

# Create venv if it doesn't exist
if [ ! -d "${VENV_DIR}" ]; then
    echo "Creating Python virtual environment..."
    python3 -m venv "${VENV_DIR}"
fi

# Install dependencies if not installed
if ! "${PYTHON}" -c "import yaml" 2>/dev/null; then
    echo "Installing PyYAML..."
    "${PYTHON}" -m pip install --quiet PyYAML
fi

# Install jinja2-cli if not installed
if ! "${PYTHON}" -c "import jinja2cli" 2>/dev/null 2>/dev/null; then
    echo "Installing jinja2-cli..."
    "${PYTHON}" -m pip install --quiet jinja2-cli
fi

cd "${PROJECT_ROOT}"

# Create tmp directory if it doesn't exist
mkdir -p "${TMP_DIR}"

# Step 1: Extract data from Terraform files to YAML
echo "1. Extracting module data from Terraform files..."
"${PYTHON}" "${SCRIPT_DIR}/generate_fqrn.py" > "${YAML_DATA}"

# Step 2: Render template using jinja2-cli
echo "2. Rendering template with Jinja2..."
${VENV_DIR}/bin/jinja2 ${TEMPLATE} ${YAML_DATA} -o ${OUTPUT}

echo "✓ Generated terraform_fqrn.tf"

