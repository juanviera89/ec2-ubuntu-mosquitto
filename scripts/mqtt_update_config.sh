#!/bin/bash

# 1. Obtener credenciales de EC2
source ./instance_role.sh
# 2. Leer secreto inicial
SECRET_VALUE=$(aws secretsmanager get-secret-value --secret-id "$1" --query 'SecretString' --output text)
# 3. Asumir rol elevado
source ./elevated_role.sh "$1"
local mqttpass $(./mqtt_update_conf_sub.sh "$SECRET_VALUE")
sudo systemctl restart mosquitto
echo "Mosquitto | configuracion actualizada correctamente."
exit 0