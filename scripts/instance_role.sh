#!/bin/bash
# 1. Obtener credenciales de EC2
INSTANCE_ROLE=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/ | jq -r 'keys[0]')
CREDENTIALS=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/$INSTANCE_ROLE)
ACCESS_KEY_ID=$(echo "$CREDENTIALS" | jq -r '.AccessKeyId')
SECRET_ACCESS_KEY=$(echo "$CREDENTIALS" | jq -r '.SecretAccessKey')
SESSION_TOKEN=$(echo "$CREDENTIALS" | jq -r '.Token')
export AWS_ACCESS_KEY_ID=$ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$SECRET_ACCESS_KEY
export AWS_SESSION_TOKEN=$SESSION_TOKEN
#Verificar las credenciales
INSTANCE_ROL_IDENTITY=$(aws sts get-caller-identity)
INSTANCE_ROL_USER_ID=$(echo "$INSTANCE_ROL_IDENTITY" | jq -r '.UserId')
INSTANCE_ROL_ACCOUNT=$(echo "$INSTANCE_ROL_IDENTITY" | jq -r '.Account')
INSTANCE_ROL_ARN=$(echo "$INSTANCE_ROL_IDENTITY" | jq -r '.Arn')
if [ -z "$INSTANCE_ROL_USER_ID" ] || [ -z "$INSTANCE_ROL_ACCOUNT" ] || [ -z "$INSTANCE_ROL_ARN" ]; then
  echo "Error: No se pudo asumir el rol de instancia."
  exit 1
fi
echo "Credenciales de EC2 obtenidas correctamente."