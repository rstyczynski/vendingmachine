#!/bin/bash

# Setup bash completion for scripts in this directory
# Usage: source ./setup_completion.sh
# Or add to ~/.bashrc: source /path/to/oci-example/bin/setup_completion.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source completion files
if [[ -f "$SCRIPT_DIR/bastion_ssh_config_completion.bash" ]]; then
  source "$SCRIPT_DIR/bastion_ssh_config_completion.bash"
  echo "Bash completion enabled for bastion_ssh_config.sh"
fi

# Add this directory to PATH if not already there
if [[ ":$PATH:" != *":$SCRIPT_DIR:"* ]]; then
  export PATH="$SCRIPT_DIR:$PATH"
  echo "Added $SCRIPT_DIR to PATH"
fi

