#!/bin/bash

terraform output -json fqrn_map | jq -r '.["instance://vm_demo/demo/app3_instance"]' > tmp/vm.ocid
vm_ocid=$(cat tmp/vm.ocid)

terraform output -json fqrn_map | jq -r '.["bastion://vm_demo/demo/demo_bastion"]' > tmp/bastion.ocid
bastion_ocid=$(cat tmp/bastion.ocid)

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