#!/bin/bash
# 1. Obtener credenciales de EC2
INSTANCE_ROLE=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/ | jq -r 'keys[0]')
CREDENTIALS=$(./instance_role.sh)
ACCESS_KEY_ID=$(echo "$CREDENTIALS" | jq -r '.AccessKeyId')
SECRET_ACCESS_KEY=$(echo "$CREDENTIALS" | jq -r '.SecretAccessKey')
SESSION_TOKEN=$(echo "$CREDENTIALS" | jq -r '.Token')
export AWS_ACCESS_KEY_ID=$ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$SECRET_ACCESS_KEY
export AWS_SESSION_TOKEN=$SESSION_TOKEN
exit 0