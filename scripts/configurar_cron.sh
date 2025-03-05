#!/bin/bash
if [ -z "$1" ]; then
echo "Error: Se debe proporcionar el argumento secret-name."
exit 1
fi
echo "Configurando CRON..."

# Verificar si el script de limpieza existe
if [ ! -f "$(dirname "$0")/clean_mqtt_logs.sh" ]; then
  echo "Error: El script clean_mqtt_logs.sh no existe en la carpeta actual."
  exit 1
fi

# 1. Obtener credenciales de EC2
source "$(dirname "$0")/instance_role.sh"

# 2. Leer secreto inicial
SECRET_VALUE=$(aws secretsmanager get-secret-value --secret-id "$1" --query 'SecretString' --output text)


# 3. Asumir rol elevado
source "$(dirname "$0")/elevated_role.sh "$1""

# 4. Leer secreto MQTT
MQTT_SECRET=$(echo "$SECRET_VALUE" | jq -r '.["mqtt-config-secret"]')
MQTT_SECRET_VALUE=$(aws secretsmanager get-secret-value --secret-id "$MQTT_SECRET" --query 'SecretString' --output text)

# 5. Copiar script de limpieza y aplicar permisos
cp "$(dirname "$0")/clean_mqtt_logs.sh" /etc/mosquitto/clean_mqtt_logs.sh
sudo chmod +x /etc/mosquitto/clean_mqtt_logs.sh

# 6. Leer configuración de cron
MQTT_CRON=$(echo "$MQTT_SECRET_VALUE" | jq -r '.["mqtt-clean-cron"]')
if [ -z "$MQTT_CRON" ]; then
echo "No hay cron configurado para limpieza."
return
fi

# 7. Configurar cron como root
CRON_LINE="$MQTT_CRON /etc/mosquitto/clean_mqtt_logs.sh"
CRON_EXIST=$(sudo crontab -l | grep "/etc/mosquitto/clean_mqtt_logs.sh")

if [ -n "$CRON_EXIST" ]; then
sudo crontab -l | grep -v "/etc/mosquitto/clean_mqtt_logs.sh" | sudo crontab -
fi

(sudo crontab -l 2>/dev/null; echo "$CRON_LINE") | sudo crontab -

echo "CRON configurado como root correctamente."
exit 0