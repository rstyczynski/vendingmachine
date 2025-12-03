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
    --private-key)
      # Complete with file paths, with preference for ~/.ssh directory
      # Also suggest auto-generated key names if host-alias was set
      local host_alias=""
      local i
      for ((i=1; i<${#COMP_WORDS[@]}; i++)); do
        if [[ "${COMP_WORDS[i]}" == "--host-alias" && $((i+1)) -lt ${#COMP_WORDS[@]} ]]; then
          host_alias="${COMP_WORDS[i+1]}"
          break
        elif [[ "${COMP_WORDS[i]}" =~ ^--host-alias= ]]; then
          host_alias="${COMP_WORDS[i]#*=}"
          break
        fi
      done
      
      # If host-alias is set, suggest the auto-generated key name
      if [[ -n "$host_alias" && -d ~/.ssh ]]; then
        local auto_key="$HOME/.ssh/${host_alias}_one_time"
        if [[ -f "$auto_key" && "$cur" == "" ]]; then
          COMPREPLY=("$auto_key")
        fi
      fi
      
      # Also complete with existing files (especially in ~/.ssh)
      COMPREPLY+=($(compgen -f -- ${cur}))
      
      # If cur starts with ~, expand it
      if [[ ${cur} == ~* ]]; then
        local expanded
        expanded=$(eval echo "$cur" 2>/dev/null)
        if [[ -n "$expanded" ]]; then
          COMPREPLY+=($(compgen -f -- "$expanded"))
        fi
      fi
      
      return 0
      ;;
    --public-key)
      # Complete with file paths, prefer .pub files
      COMPREPLY=($(compgen -f -X '!*.pub' -- ${cur}))
      # Also complete all files if no .pub matches
      if [[ ${#COMPREPLY[@]} -eq 0 ]]; then
        COMPREPLY=($(compgen -f -- ${cur}))
      fi
      return 0
      ;;
    --instance-ocid|--bastion-ocid)
      # These can be OCIDs (ocid1.*) or FQRNs (scheme://...)
      if [[ ${cur} == ocid1.* ]] || [[ ${cur} == *://* ]]; then
        # Don't complete, let user type
        COMPREPLY=()
        return 0
      fi
      # Suggest FQRN schemes if starting with a scheme
      if [[ ${cur} == instance://* ]] || [[ ${cur} == bastion://* ]]; then
        COMPREPLY=()
        return 0
      fi
      # If starting fresh, suggest FQRN format
      if [[ ${cur} == "" ]]; then
        if [[ "${prev}" == "--instance-ocid" ]]; then
          COMPREPLY=("instance://")
        elif [[ "${prev}" == "--bastion-ocid" ]]; then
          COMPREPLY=("bastion://")
        fi
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
      # Also check for existing _one_time keys in ~/.ssh
      local existing_aliases=("oci-bastion-host" "bastion" "oci-host")
      if [[ -d ~/.ssh ]]; then
        while IFS= read -r keyfile; do
          if [[ "$keyfile" =~ _one_time$ ]]; then
            local alias_name="${keyfile%_one_time}"
            existing_aliases+=("$alias_name")
          fi
        done < <(ls -1 ~/.ssh/*_one_time 2>/dev/null | xargs -n1 basename 2>/dev/null)
      fi
      COMPREPLY=($(compgen -W "${existing_aliases[*]}" -- ${cur}))
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

