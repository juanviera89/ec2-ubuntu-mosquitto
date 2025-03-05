#!/bin/bash
# 1. Obtener credenciales de EC2
source "$(dirname "$0")/instance_role.sh"

# 2. Leer secreto inicial
SECRET_VALUE=$(aws secretsmanager get-secret-value --secret-id "$1" --query 'SecretString' --output text)

# 3. Asumir rol elevado
ELEVATED_ROLE=$(echo "$SECRET_VALUE" | jq -r '.["elevated-rol"]')
ELEVATED_CREDENTIALS=$(aws sts assume-role --role-arn "$ELEVATED_ROLE" --role-session-name SesionCLI)

export AWS_ACCESS_KEY_ID=$(jq -r '.Credentials.AccessKeyId' <<< "$ELEVATED_CREDENTIALS")
export AWS_SECRET_ACCESS_KEY=$(jq -r '.Credentials.SecretAccessKey' <<< "$ELEVATED_CREDENTIALS")
export AWS_SESSION_TOKEN=$(jq -r '.Credentials.SessionToken' <<< "$ELEVATED_CREDENTIALS")

ELEVATED_ROL_IDENTITY = "$(aws sts get-caller-identity)"
ELEVATED_ROL_USER_ID= $(echo "$ELEVATED_ROL_IDENTITY" | jq -r '.UserId')
ELEVATED_ROL_ACCOUNT= $(echo "$ELEVATED_ROL_IDENTITY" | jq -r '.Account')
ELEVATED_ROLE_NAME=$(echo "$ELEVATED_ROLE" | cut -d ':' -f 6)
ELEVATED_ROL_ARN=$(echo "$ELEVATED_ROL_IDENTITY" | jq -r '.Arn' | grep "$ELEVATED_ROLE_NAME" )

if [ -z "$ELEVATED_ROL_USER_ID" ] || [ -z "$ELEVATED_ROL_ACCOUNT" ] || [ -z "$ELEVATED_ROL_ARN" ]; then
  echo "Error: No se pudo asumir el rol elevado."
  exit 1
fi
#echo "Rol elevado asumido correctamente."