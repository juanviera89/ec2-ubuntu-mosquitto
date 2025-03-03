#!/bin/bash
# Verificar si se proporciona el argumento secret-name
if [ -z "$1" ]; then
echo "Error: Se debe proporcionar el argumento secret-name."
exit 1
fi
echo "Instalando y configurando Mosquitto..."

# Instalar Mosquitto
sudo apt update
sudo apt install mosquitto mosquitto-clients -y

# 1. Obtener credenciales de EC2
source ./instance_role.sh

# 2. Leer secreto inicial
SECRET_VALUE=$(aws secretsmanager get-secret-value --secret-id "$1" --query 'SecretString' --output text)

# 3. Asumir rol elevado
source ./elevated_role.sh "$1"

# 4. Escribir configuracion de mosquitto
local mqttconf $(./mqtt_update_conf_sub.sh "$SECRET_VALUE")

# 6. Escribir contraseñas de Mosquitto
local mqttpass $(./mqtt_update_pass_sub.sh "$SECRET_VALUE")

# 7. Reiniciar Mosquitto
sudo systemctl restart mosquitto

echo "Mosquitto instalado y configurado correctamente."
echo "Para mejor manejo de logs, se sugiere reemplazar el uso de cron de limpieza por la herramienta logrotate que puede ayudar a extender los tiempos almacenados, comprimiendo logs antiguos pero tambien eliminando los muy antiguos"
exit 0