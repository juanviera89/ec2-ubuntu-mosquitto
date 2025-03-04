#!/bin/bash

# Variables
SNS_TOPIC_FILE="/mosquitto/sns_topic_arn.txt"

# Obtener ARN del tema de SNS desde Secrets Manager
source ./instance_role.sh # Obtener credenciales de instancia

SECRET_NAME=$(aws secretsmanager get-secret-value --secret-id "$1" --query 'SecretString' --output text)

source ./elevated_role.sh # Asumir rol elevado

SNS_TOPIC_ARN=$(aws secretsmanager get-secret-value --secret-id "$SECRET_NAME" --query 'SecretString' --output text | jq -r '.sns_topic_arn')

# Verificar si se obtuvo el ARN del tema de SNS
if [ -z "$SNS_TOPIC_ARN" ]; then
  echo "Error: No se pudo obtener el ARN del tema de SNS desde Secrets Manager."
  exit 1
fi

# Guardar ARN del tema de SNS en archivo local
echo "$SNS_TOPIC_ARN" > "$SNS_TOPIC_FILE"

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Agregar cronjob para verificar Mosquitto cada 10 segundos
(crontab -l 2>/dev/null; echo "*/10 * * * * $SCRIPT_DIR/verificar_mosquitto.sh") | crontab -

echo "Cronjob configurado para verificar Mosquitto cada 10 segundos."