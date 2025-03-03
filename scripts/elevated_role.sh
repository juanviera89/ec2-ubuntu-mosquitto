#!/bin/bash
# 1. Obtener credenciales de EC2
source ./instance_role.sh

# 2. Leer secreto inicial
SECRET_VALUE=$(aws secretsmanager get-secret-value --secret-id "$1" --query 'SecretString' --output text)

# 3. Asumir rol elevado
ELEVATED_ROLE=$(echo "$SECRET_VALUE" | jq -r '.elevated-rol')
ELEVATED_CREDENTIALS=$(aws sts assume-role --role-arn "$ELEVATED_ROLE" --role-session-name SesionCLI)

export AWS_ACCESS_KEY_ID=$(jq -r '.Credentials.AccessKeyId' <<< "$ELEVATED_CREDENTIALS")
export AWS_SECRET_ACCESS_KEY=$(jq -r '.Credentials.SecretAccessKey' <<< "$ELEVATED_CREDENTIALS")
export AWS_SESSION_TOKEN=$(jq -r '.Credentials.SessionToken' <<< "$ELEVATED_CREDENTIALS")
exit 0