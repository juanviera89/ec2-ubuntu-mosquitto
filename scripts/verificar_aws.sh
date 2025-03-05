#!/bin/bash

# 2.1 Verificar AWS CLI
if ! command -v aws &> /dev/null; then
  echo "FAIL: AWS CLI no está instalado."
  exit 1
fi


# 1. Obtener credenciales de EC2
source "$(dirname "$0")/instance_role.sh" 

#Verificar las credenciales
INSTANCE_ROL_IDENTITY="$(aws sts get-caller-identity)"
INSTANCE_ROL_USER_ID=$(echo "$INSTANCE_ROL_IDENTITY" | jq -r '.UserId')
INSTANCE_ROL_ACCOUNT=$(echo "$INSTANCE_ROL_IDENTITY" | jq -r '.Account')
INSTANCE_ROL_ARN=$(echo "$INSTANCE_ROL_IDENTITY" | jq -r '.Arn')

if [ -z "$INSTANCE_ROL_USER_ID" ] || [ -z "$INSTANCE_ROL_ACCOUNT" ] || [ -z "$INSTANCE_ROL_ARN" ]; then
  echo "FAIL: No se pudo asumir el rol de instancia."
  exit 1
fi

# 2.3 Leer secreto inicial
SECRET_VALUE=$(aws secretsmanager get-secret-value --secret-id "$1" --query 'SecretString' --output text)
if [ -z "$SECRET_VALUE" ]; then
  echo "FAIL: No se puede leer el secreto $1."
  exit 1
fi

# 2.4 Asumir rol elevado
ELEVATED_ROLE=$(echo "$SECRET_VALUE" | jq -r '.["elevated-rol"]')
if [ -z "$ELEVATED_ROLE" ]; then
  echo "FAIL: No se encuentra el rol elevado en el secreto."
  echo "$SECRET_VALUE"
  exit 1
fi

ELEVATED_CREDENTIALS=$(aws sts assume-role --role-arn "$ELEVATED_ROLE" --role-session-name SesionCLI)

if [ -z "$ELEVATED_CREDENTIALS" ]; then
  echo "FAIL: No se pueden obtener las credenciales elevadas."
  exit 1
fi
export AWS_ACCESS_KEY_ID=$(jq -r '.Credentials.AccessKeyId' <<< "$ELEVATED_CREDENTIALS")
export AWS_SECRET_ACCESS_KEY=$(jq -r '.Credentials.SecretAccessKey' <<< "$ELEVATED_CREDENTIALS")
export AWS_SESSION_TOKEN=$(jq -r '.Credentials.SessionToken' <<< "$ELEVATED_CREDENTIALS")

#Verificar las credenciales
ELEVATED_ROL_IDENTITY="$(aws sts get-caller-identity)"
ELEVATED_ROL_USER_ID=$(echo "$ELEVATED_ROL_IDENTITY" | jq -r '.UserId')
ELEVATED_ROL_ACCOUNT=$(echo "$ELEVATED_ROL_IDENTITY" | jq -r '.Account')
ELEVATED_ROLE_NAME=$(echo "$ELEVATED_ROLE" | cut -d ':' -f 6)
ELEVATED_ROL_ARN=$(echo "$ELEVATED_ROL_IDENTITY" | jq -r '.Arn' | grep "$ELEVATED_ROLE_NAME" )

if [ -z "$ELEVATED_ROL_USER_ID" ] || [ -z "$ELEVATED_ROL_ACCOUNT" ] || [ -z "$ELEVATED_ROL_ARN" ]; then
  echo "Error: No se pudo asumir el rol elevado."
  exit 1
fi

# 2.5 Leer secreto MQTT
MQTT_SECRET=$(echo "$SECRET_VALUE" | jq -r '.["mqtt-config-secret"]')
if [ -z "$MQTT_SECRET" ]; then
  echo "FAIL: No se encuentra el secreto MQTT en el secreto inicial."
  exit 1
fi
MQTT_SECRET_VALUE=$(aws secretsmanager get-secret-value --secret-id "$MQTT_SECRET" --query 'SecretString' --output text)
if [ -z "$MQTT_SECRET_VALUE" ]; then
  echo "FAIL: No se puede leer el secreto MQTT $MQTT_SECRET."
  exit 1
fi

echo "SUCCESS"
exit 0