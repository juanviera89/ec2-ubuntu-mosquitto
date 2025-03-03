#!/bin/bash
# Verificar si se proporciona el argumento secret-value
if [ -z "$1" ]; then
echo "Error: Se debe proporcionar el argumento secret-value."
exit 1
fi
# 4. Leer secreto MQTT
MQTT_SECRET=$(echo "$1" | jq -r '.mqtt-config-secret')
MQTT_SECRET_VALUE=$(aws secretsmanager get-secret-value --secret-id "$MQTT_SECRET" --query 'SecretString' --output text)

MQTT_PASS=$(echo "$MQTT_SECRET_VALUE" | jq -r '.mqtt-pass')
echo "$MQTT_PASS" > "/mosquitto/config/pass.txt"
exit 0