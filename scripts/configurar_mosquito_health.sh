#!/bin/bash
if [ -z "$1" ]; then
echo "Error: Se debe proporcionar el argumento secret-name."
exit 1
fi
# Variables
SNS_TOPIC_FILE="/etc/mosquitto/sns_topic_arn.txt"

# Obtener ARN del tema de SNS desde Secrets Manager
source "$(dirname "$0")/instance_role.sh" # Obtener credenciales de instancia

SECRET_NAME=$(aws secretsmanager get-secret-value --secret-id "$1" --query 'SecretString' --output text)

source "$(dirname "$0")/elevated_role.sh"  "$1" # Asumir rol elevado
MQTT_SECRET=$(echo "$SECRET_VALUE" | jq -r '.["mqtt-config-secret"]')
SNS_TOPIC_ARN=$(aws secretsmanager get-secret-value --secret-id "$MQTT_SECRET" --query 'SecretString' --output text | jq -r '.["sns_topic_arn"]')

# Verificar si se obtuvo el ARN del tema de SNS
if [ -z "$SNS_TOPIC_ARN" ]; then
  echo "Error: No se pudo obtener el ARN del tema de SNS desde Secrets Manager."
  exit 1
fi

# Guardar ARN del tema de SNS en archivo local
sudo echo "$SNS_TOPIC_ARN" > "$SNS_TOPIC_FILE"

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# 7. Configurar cron 
CRON_EXIST=$(sudo crontab -l | grep "$SCRIPT_DIR/verificar_mosquitto.sh")

if [ -n "$CRON_EXIST" ]; then
sudo crontab -l | grep -v "$SCRIPT_DIR/verificar_mosquitto.sh" | sudo crontab -
fi

# Agregar cronjob para verificar Mosquitto cada 10 segundos
(crontab -l 2>/dev/null; echo "*/10 * * * * $SCRIPT_DIR/verificar_mosquitto.sh") | crontab -

echo "Cronjob configurado para verificar Mosquitto cada 10 segundos."