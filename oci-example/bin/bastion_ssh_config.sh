#!/bin/bash

# Usage: bastion_ssh_config.sh [OPTIONS]
#
# Options:
#   --instance-ocid OCID|FQRN      Instance OCID or FQRN (e.g., instance://path/name) (required)
#   --bastion-ocid OCID|FQRN      Bastion OCID or FQRN (e.g., bastion://path/name) (required)
#   --session-ttl SECONDS          Session TTL in seconds (default: 3600)
#   --private-key PATH             Private key file path (default: ~/.ssh/id_rsa)
#   --public-key PATH              Public key file path (default: <private-key>.pub)
#   --host-alias NAME              SSH config host alias (default: oci-bastion-host)
#   --target-os-username USER      Target OS username (default: opc)
#   --help                         Show this help message

set -euo pipefail

# Get script directory and set tmp directory relative to script (../tmp)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="$SCRIPT_DIR/../tmp"
mkdir -p "$TMP_DIR"

# Default values
SESSION_TTL="3600"
PRIVATE_KEY="$HOME/.ssh/id_rsa"
PUBLIC_KEY=""
HOST_ALIAS="oci-bastion-host"
TARGET_OS_USERNAME="opc"
INSTANCE_OCID=""
BASTION_OCID=""

# Parse named arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --instance-ocid)
      INSTANCE_OCID="$2"
      shift 2
      ;;
    --instance-ocid=*)
      INSTANCE_OCID="${1#*=}"
      shift
      ;;
    --bastion-ocid)
      BASTION_OCID="$2"
      shift 2
      ;;
    --bastion-ocid=*)
      BASTION_OCID="${1#*=}"
      shift
      ;;
    --session-ttl)
      SESSION_TTL="$2"
      shift 2
      ;;
    --session-ttl=*)
      SESSION_TTL="${1#*=}"
      shift
      ;;
    --private-key)
      PRIVATE_KEY="$2"
      shift 2
      ;;
    --private-key=*)
      PRIVATE_KEY="${1#*=}"
      shift
      ;;
    --public-key)
      PUBLIC_KEY="$2"
      shift 2
      ;;
    --public-key=*)
      PUBLIC_KEY="${1#*=}"
      shift
      ;;
    --host-alias)
      HOST_ALIAS="$2"
      shift 2
      ;;
    --host-alias=*)
      HOST_ALIAS="${1#*=}"
      shift
      ;;
    --target-os-username)
      TARGET_OS_USERNAME="$2"
      shift 2
      ;;
    --target-os-username=*)
      TARGET_OS_USERNAME="${1#*=}"
      shift
      ;;
    --help|-h)
      sed -n '/^# Usage:/,/^$/p' "$0" | sed 's/^# //'
      exit 0
      ;;
    -*)
      echo "Error: Unknown option: $1" >&2
      echo "Use --help for usage information" >&2
      exit 1
      ;;
    *)
      echo "Error: Positional arguments are not supported: $1" >&2
      echo "Use named arguments with -- prefix (e.g., --instance-ocid OCID)" >&2
      echo "Use --help for usage information" >&2
      exit 1
      ;;
  esac
done

# Set default public key if not provided
if [[ -z "$PUBLIC_KEY" ]]; then
  PUBLIC_KEY="${PRIVATE_KEY}.pub"
fi

# Validate required arguments
if [[ -z "$INSTANCE_OCID" ]]; then
  echo "Error: --instance-ocid is required" >&2
  exit 1
fi

if [[ -z "$BASTION_OCID" ]]; then
  echo "Error: --bastion-ocid is required" >&2
  exit 1
fi

# Validate files exist
if [[ ! -f "$PRIVATE_KEY" ]]; then
  echo "Error: Private key file not found: $PRIVATE_KEY" >&2
  exit 1
fi

if [[ ! -f "$PUBLIC_KEY" ]]; then
  echo "Error: Public key file not found: $PUBLIC_KEY" >&2
  exit 1
fi

# Function to resolve FQRN to OCID
resolve_fqrn_to_ocid() {
  local input="$1"
  local resource_type="$2"
  
  # If it's already an OCID (starts with ocid1.), return as-is
  if [[ "$input" =~ ^ocid1\. ]]; then
    echo "$input"
    return 0
  fi
  
  # If it's an FQRN (contains ://), resolve it
  if [[ "$input" =~ :// ]]; then
    # Check if terraform is available
    if ! command -v terraform &> /dev/null; then
      echo "Error: terraform command not found. Cannot resolve FQRN '$input'." >&2
      exit 1
    fi
    
    # Check if jq is available
    if ! command -v jq &> /dev/null; then
      echo "Error: jq command not found. Cannot resolve FQRN '$input'." >&2
      exit 1
    fi
    
    # Try to resolve from terraform output
    # Change to parent directory (one level up from bin) to find terraform state
    local terraform_dir="$SCRIPT_DIR/.."
    local ocid
    ocid=$(cd "$terraform_dir" && terraform output -json fqrn_map 2>/dev/null | jq -r --arg fqrn "$input" '.[$fqrn] // empty')
    
    if [[ -z "$ocid" || "$ocid" == "null" ]]; then
      echo "Error: Could not resolve FQRN '$input' to OCID." >&2
      echo "Make sure:" >&2
      echo "  1. You are in a terraform directory or run from oci-example/bin" >&2
      echo "  2. terraform output fqrn_map contains this FQRN" >&2
      echo "  3. Terraform state is initialized (terraform init)" >&2
      exit 1
    fi
    
    echo "$ocid"
    return 0
  fi
  
  # Neither OCID nor FQRN format
  echo "Error: Invalid format for $resource_type: '$input'. Must be an OCID (ocid1.*) or FQRN (*://*)" >&2
  exit 1
}

# Resolve FQRNs to OCIDs if needed
echo "Resolving instance identifier..." >&2
INSTANCE_OCID_RESOLVED=$(resolve_fqrn_to_ocid "$INSTANCE_OCID" "instance-ocid")

echo "Resolving bastion identifier..." >&2
BASTION_OCID_RESOLVED=$(resolve_fqrn_to_ocid "$BASTION_OCID" "bastion-ocid")

# Create bastion session
oci bastion session create-managed-ssh \
  --bastion-id "$BASTION_OCID_RESOLVED" \
  --target-resource-id "$INSTANCE_OCID_RESOLVED" \
  --target-os-username "$TARGET_OS_USERNAME" \
  --key-type PUB \
  --ssh-public-key-file "$PUBLIC_KEY" \
  --session-ttl "$SESSION_TTL" \
  --wait-for-state SUCCEEDED > "$TMP_DIR/managed-ssh.json"

# Get session details
session_ocid=$(jq -r .data.resources[0].identifier "$TMP_DIR/managed-ssh.json")
private_key="$PRIVATE_KEY"
oci bastion session get \
  --session-id "$session_ocid" > "$TMP_DIR/session.json"

jq -r '.data."ssh-metadata".command' "$TMP_DIR/session.json" | sed "s|<privateKey>|$private_key|g" > "$TMP_DIR/session.sh"

SSH_CMD=$(cat "$TMP_DIR/session.sh")

# Ensure ~/.ssh/config exists
mkdir -p ~/.ssh
touch ~/.ssh/config

# Remove existing host entry by name (if it exists)
if [[ -f ~/.ssh/config ]]; then
  awk -v host="$HOST_ALIAS" '
    $1=="Host" && $2==host {skip=1; next}
    $1=="Host" {skip=0}
    !skip
  ' ~/.ssh/config > ~/.ssh/config.tmp && mv ~/.ssh/config.tmp ~/.ssh/config
fi

# Extract components
PRIVATE_KEY=$(echo "$SSH_CMD" | grep -oE '\-i [^ ]+' | head -1 | cut -d' ' -f2)
BASTION_SESSION=$(echo "$SSH_CMD" | grep -oE 'ocid1\.bastionsession[^@]+@[^ "]+')
USER_HOST=$(echo "$SSH_CMD" | grep -oE '[a-z]+@[0-9.]+$')
USER=$(echo "$USER_HOST" | cut -d'@' -f1)
HOST=$(echo "$USER_HOST" | cut -d'@' -f2)

cat >>~/.ssh/config <<EOF
Host $HOST_ALIAS
  HostName $HOST
  User $USER
  IdentityFile $PRIVATE_KEY
  ProxyCommand ssh -i $PRIVATE_KEY -W %h:%p -p 22 $BASTION_SESSION
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
EOF

echo "SSH config entry added for host: $HOST_ALIAS"
echo "Connect using: ssh $HOST_ALIAS"