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
echo "$MQTT_CONF" > "/etc/mosquitto/conf.d/mqtt1.conf"
sudo iconv -f ISO-8859-1 -t UTF-8 /etc/mosquitto/conf.d/mqtt1.conf -o /etc/mosquitto/conf.d/mqtt1.conf.utf8
sudo mv /etc/mosquitto/conf.d/mqtt1.conf.utf8 /etc/mosquitto/conf.d/mqtt1.conf
sudo chmod 644 /etc/mosquitto/conf.d/mqtt1.conf # Required by mosquitto
chown root /etc/mosquitto/conf.d/mqtt1.conf # Required by mosquitto
sudo systemctl daemon-reload
sudo systemctl restart mosquitto
exit 0