#!/bin/bash
# Verificar si se proporciona el argumento secret-value
if [ -z "$1" ]; then
echo "Error: Se debe proporcionar el argumento secret-value."
exit 1
fi
# 4. Leer secreto MQTT
MQTT_SECRET=$(echo "$1" | jq -r '.["mqtt-config-secret"]')
MQTT_SECRET_VALUE=$(aws secretsmanager get-secret-value --secret-id "$MQTT_SECRET" --query 'SecretString' --output text)

# 5. Escribir configuración de Mosquitto
MQTT_CONF=$(echo "$MQTT_SECRET_VALUE" | jq -r '.["mqtt-conf"]')
echo "$MQTT_CONF" > "/etc/mosquitto/conf.d/mosquitto.conf"
exit 0