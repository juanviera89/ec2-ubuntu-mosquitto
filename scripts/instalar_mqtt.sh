#!/bin/bash
# Verificar si se proporciona el argumento secret-name
if [ -z "$1" ]; then
echo "Error: Se debe proporcionar el argumento secret-name."
exit 1
fi
echo "Instalando y configurando Mosquitto..."

DIR_NAME=$(dirname "$0")

# Instalar Mosquitto
sudo apt update
sudo apt install mosquitto mosquitto-clients -y

# Verificar instalación
if ! command -v mosquitto &> /dev/null; then
  echo "Error: Mosquitto no se instaló correctamente."
  exit 1
fi
# Verificar servicio Mosquitto
if ! systemctl is-enabled mosquitto &> /dev/null; then
  echo "Advertencia: El servicio Mosquitto no está habilitado. Intentando habilitarlo..."
  sudo systemctl enable mosquitto
  if [ $? -ne 0 ]; then
    echo "Error: No se pudo habilitar el servicio Mosquitto."
    exit 1
  fi
  echo "Servicio Mosquitto habilitado correctamente."
fi
# 1. Obtener credenciales de EC2
ROLE_SCRIPT="$DIR_NAME/instance_role.sh"
source "$ROLE_SCRIPT"

# 2. Leer secreto inicial
SECRET_VALUE=$(aws secretsmanager get-secret-value --secret-id "$1" --query 'SecretString' --output text)

# 3. Asumir rol elevado
ELEVATED_ROLE_SCRIPT="$DIR_NAME/elevated_role.sh"
source "$ELEVATED_ROLE_SCRIPT" "$1"

# 4. Escribir configuracion de mosquitto
"$DIR_NAME/mqtt_update_conf_sub.sh" "$SECRET_VALUE"

# 6. Escribir contraseñas de Mosquitto
"$DIR_NAME/mqtt_update_pass_sub.sh" "$SECRET_VALUE"

# 7. Reiniciar Mosquitto
sudo systemctl restart mosquitto

echo "Mosquitto instalado y configurado correctamente."
echo "Para mejor manejo de logs, se sugiere reemplazar el uso de cron de limpieza por la herramienta logrotate que puede ayudar a extender los tiempos almacenados, comprimiendo logs antiguos pero tambien eliminando los muy antiguos"
exit 0