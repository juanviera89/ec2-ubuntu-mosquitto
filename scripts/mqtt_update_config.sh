#!/bin/bash
DIR_NAME=$(dirname "$0")
# 1. Obtener credenciales de EC2
source "$DIR_NAME/instance_role.sh"
# 2. Leer secreto inicial
SECRET_VALUE=$(aws secretsmanager get-secret-value --secret-id "$1" --query 'SecretString' --output text)
# 3. Asumir rol elevado
ELEVATED_ROLE_SCRIPT="$DIR_NAME/elevated_role.sh"
source "$ELEVATED_ROLE_SCRIPT" "$1"
"$DIR_NAME/mqtt_update_conf_sub.sh" "$SECRET_VALUE"
sudo systemctl restart mosquitto
echo "Mosquitto | configuracion actualizada correctamente."
exit 0