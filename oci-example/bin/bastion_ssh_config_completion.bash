#!/bin/bash

# Bash completion for bastion_ssh_config.sh
# To enable: source this file or add to ~/.bashrc:
#   source /path/to/oci-example/bin/bastion_ssh_config_completion.bash

_bastion_ssh_config_complete() {
  local cur prev opts
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  
  # List of available options
  opts="--instance-ocid --bastion-ocid --session-ttl --private-key --public-key --host-alias --target-os-username --help"
  
  # If current word starts with --, complete from options
  if [[ ${cur} == --* ]]; then
    COMPREPLY=($(compgen -W "${opts}" -- ${cur}))
    return 0
  fi
  
  # Complete based on previous option
  case "${prev}" in
    --private-key|--public-key)
      # Complete with file paths
      COMPREPLY=($(compgen -f -- ${cur}))
      return 0
      ;;
    --instance-ocid|--bastion-ocid)
      # These typically start with "ocid1."
      if [[ ${cur} == ocid1.* ]]; then
        # Don't complete, let user type
        COMPREPLY=()
        return 0
      fi
      ;;
    --session-ttl)
      # Suggest common TTL values
      COMPREPLY=($(compgen -W "1800 3600 7200 10800" -- ${cur}))
      return 0
      ;;
    --target-os-username)
      # Suggest common usernames
      COMPREPLY=($(compgen -W "opc oracle ubuntu admin root" -- ${cur}))
      return 0
      ;;
    --host-alias)
      # Suggest common host aliases
      COMPREPLY=($(compgen -W "oci-bastion-host bastion oci-host" -- ${cur}))
      return 0
      ;;
  esac
  
  # Default: complete with options if we're at the start
  if [[ ${COMP_CWORD} -eq 1 ]]; then
    COMPREPLY=($(compgen -W "${opts}" -- ${cur}))
  fi
}

# Register completion function for various ways the script might be called
complete -F _bastion_ssh_config_complete bastion_ssh_config.sh
complete -F _bastion_ssh_config_complete ./bastion_ssh_config.sh

# Register for script in bin directory (common usage)
if [[ -n "${BASH_SOURCE[0]}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  complete -F _bastion_ssh_config_complete "$SCRIPT_DIR/bastion_ssh_config.sh"
fi

