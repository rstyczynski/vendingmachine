#!/bin/bash

# arguments:
# 1. instance ocid
# 2. bastion ocid
# 3. session ttl
# 4. rsa key file priv - default ~/.ssh/id_rsa
# 5. rsa key file pub - default $private_key.pub
# 6. host alias in ssh config

set -euo pipefail

# Get script directory and set tmp directory relative to script (../tmp)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="$SCRIPT_DIR/../tmp"

# Parse arguments
INSTANCE_OCID="${1:?Error: Instance OCID required as first argument}"
BASTION_OCID="${2:?Error: Bastion OCID required as second argument}"
SESSION_TTL="${3:-3600}"
PRIVATE_KEY="${4:-$HOME/.ssh/id_rsa}"
PUBLIC_KEY="${5:-${PRIVATE_KEY}.pub}"
HOST_ALIAS="${6:-oci-bastion-host}"

# Validate files exist
if [[ ! -f "$PRIVATE_KEY" ]]; then
  echo "Error: Private key file not found: $PRIVATE_KEY" >&2
  exit 1
fi

if [[ ! -f "$PUBLIC_KEY" ]]; then
  echo "Error: Public key file not found: $PUBLIC_KEY" >&2
  exit 1
fi

# Create tmp directory if it doesn't exist (relative to script location)
mkdir -p "$TMP_DIR"

# Create bastion session
oci bastion session create-managed-ssh \
  --bastion-id $bastion_ocid \
  --target-resource-id $vm_ocid \
  --target-os-username opc \
  --key-type PUB \
  --ssh-public-key-file ~/.ssh/id_rsa.pub \
  --session-ttl 3600 \
  --wait-for-state SUCCEEDED > tmp/managed-ssh.json

# Get sessi details
session_ocid=$(jq -r .data.resources[0].identifier tmp/managed-ssh.json)
private_key=~/.ssh/id_rsa
oci bastion session get \
  --session-id $session_ocid >tmp/session.json

jq -r '.data."ssh-metadata".command' tmp/session.json | sed "s|<privateKey>|$private_key|g" > tmp/session.sh

SSH_CMD=$(cat tmp/session.sh)
HOST_ALIAS="${2:-oci-bastion-host}"

# Remove host entry by name
awk -v host="$HOST_ALIAS" '
  $1=="Host" && $2==host {skip=1; next}
  $1=="Host" {skip=0}
  !skip
' ~/.ssh/config > ~/.ssh/config.tmp && mv ~/.ssh/config.tmp ~/.ssh/config

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