#!/bin/bash

# 2.1 Verificar AWS CLI
if ! command -v aws &> /dev/null; then
  echo "FAIL: AWS CLI no está instalado."
  exit 1
fi

# 2.2 Obtener credenciales de EC2
INSTANCE_ROLE=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/ | jq -r 'keys[0]')
CREDENTIALS=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/$INSTANCE_ROLE)
if [ -z "$CREDENTIALS" ]; then
  echo "FAIL: No se pueden obtener las credenciales de EC2."
  exit 1
fi
# 1. Obtener credenciales de EC2
source ./instance_role.sh

if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ] || [ -z "$AWS_SESSION_TOKEN" ]; then
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
ELEVATED_ROLE=$(echo "$SECRET_VALUE" | jq -r '.elevated-rol')
if [ -z "$ELEVATED_ROLE" ]; then
  echo "FAIL: No se encuentra el rol elevado en el secreto."
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

if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ] || [ -z "$AWS_SESSION_TOKEN" ]; then
  echo "FAIL: No se pudo asumir el rol elevado."
  exit 1
fi

# 2.5 Leer secreto MQTT
MQTT_SECRET=$(echo "$SECRET_VALUE" | jq -r '.mqtt-config-secret')
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