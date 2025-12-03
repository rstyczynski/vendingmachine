#!/bin/bash

# Bash completion for check_dependencies.py
# To enable: source this file or add to ~/.bashrc:
#   source /path/to/oci-example/bin/check_dependencies_completion.bash

_check_dependencies_complete() {
  local cur prev opts
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  
  # Options
  opts="--with-descriptions -d --direct --debug --help"
  
  # Try to find the script directory and YAML file
  local script_dir
  if [[ -n "${BASH_SOURCE[0]}" ]]; then
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  else
    # Fallback: try to find from common locations
    script_dir="$(cd "$(dirname "${COMP_WORDS[0]}")" && pwd 2>/dev/null)"
  fi
  
  local yaml_path="${script_dir}/../doc/resource_dependencies.yaml"
  
  # Get available resources from YAML file
  local resources=()
  if [[ -f "$yaml_path" ]]; then
    # Extract resource names from YAML
    # Look for lines under "resources:" section that define resource keys
    local in_resources=false
    while IFS= read -r line; do
      # Check if we're entering the resources section
      if [[ "$line" =~ ^resources: ]]; then
        in_resources=true
        continue
      fi
      # If we hit another top-level key, stop
      if [[ "$in_resources" == true ]] && [[ "$line" =~ ^[a-zA-Z_]+: ]] && [[ ! "$line" =~ ^[[:space:]] ]]; then
        break
      fi
      # Match resource definitions (2 spaces indent, resource name, colon)
      if [[ "$in_resources" == true ]] && [[ "$line" =~ ^[[:space:]]{2}[a-zA-Z0-9_]+: ]]; then
        local resource_name="${line%%:*}"
        resource_name="${resource_name// /}"
        if [[ -n "$resource_name" && ! "$resource_name" =~ ^# ]]; then
          resources+=("$resource_name")
        fi
      fi
    done < "$yaml_path"
  fi
  
  # If current word starts with -- or -, complete from options
  if [[ ${cur} == --* ]] || [[ ${cur} == -* ]]; then
    COMPREPLY=($(compgen -W "${opts}" -- ${cur}))
    return 0
  fi
  
  # If previous word is an option that takes no arguments, or we're at position 1, complete with resources
  if [[ ${COMP_CWORD} -eq 1 ]] || [[ "${prev}" == "--with-descriptions" ]] || [[ "${prev}" == "-d" ]] || [[ "${prev}" == "--direct" ]] || [[ "${prev}" == "--debug" ]]; then
    if [[ ${#resources[@]} -gt 0 ]]; then
      COMPREPLY=($(compgen -W "${resources[*]}" -- ${cur}))
    else
      # Fallback: suggest common resource names
      COMPREPLY=($(compgen -W "compute_instance subnet vcn compartment zone bastion nsg" -- ${cur}))
    fi
    return 0
  fi
  
  # Default: complete with resources if we're at position 1, or options if starting with -
  if [[ ${COMP_CWORD} -eq 1 ]]; then
    if [[ ${cur} == -* ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- ${cur}))
    elif [[ ${#resources[@]} -gt 0 ]]; then
      COMPREPLY=($(compgen -W "${resources[*]}" -- ${cur}))
    fi
  fi
}

# Register completion function for various ways the script might be called
complete -F _check_dependencies_complete check_dependencies.py
complete -F _check_dependencies_complete ./check_dependencies.py

# Register for script in bin directory (common usage)
if [[ -n "${BASH_SOURCE[0]}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  complete -F _check_dependencies_complete "$SCRIPT_DIR/check_dependencies.py"
fi

