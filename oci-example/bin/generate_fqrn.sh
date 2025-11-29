#!/bin/bash
# Generate all_fqrn.tf using Python venv and Jinja2 template

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
VENV_DIR="${PROJECT_ROOT}/.venv"
PYTHON="${VENV_DIR}/bin/python"

# Create venv if it doesn't exist
if [ ! -d "${VENV_DIR}" ]; then
    echo "Creating Python virtual environment..."
    python3 -m venv "${VENV_DIR}"
fi

# Install jinja2 if not installed
if ! "${PYTHON}" -c "import jinja2" 2>/dev/null; then
    echo "Installing jinja2..."
    "${PYTHON}" -m pip install --quiet jinja2
fi

# Run the generation script
echo "Generating terraform_fqrn.tf..."
cd "${PROJECT_ROOT}"
"${PYTHON}" "${SCRIPT_DIR}/generate_fqrn.py"

