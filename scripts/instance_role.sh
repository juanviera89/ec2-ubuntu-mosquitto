#!/bin/bash
# 1. Obtener credenciales de EC2
INSTANCE_ROLE=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/ | jq -r 'keys[0]')
CREDENTIALS=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/$INSTANCE_ROLE)
if [ -z "$CREDENTIALS" ]; then
  echo "Error: No se pueden obtener las credenciales de EC2."
  exit 1
fi
ACCESS_KEY_ID=$(echo "$CREDENTIALS" | jq -r '.AccessKeyId')
SECRET_ACCESS_KEY=$(echo "$CREDENTIALS" | jq -r '.SecretAccessKey')
SESSION_TOKEN=$(echo "$CREDENTIALS" | jq -r '.Token')
export AWS_ACCESS_KEY_ID=$ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$SECRET_ACCESS_KEY
export AWS_SESSION_TOKEN=$SESSION_TOKEN
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ] || [ -z "$AWS_SESSION_TOKEN" ]; then
  echo "Error: No se pudieron obtener las credenciales de EC2."
  exit 1
fi
echo "Credenciales de EC2 obtenidas correctamente."
exit 0