#!/bin/bash
# Verificar si se proporciona el argumento secret-name
if [ -z "$1" ]; then
echo "Error: Se debe proporcionar el argumento secret-name."
exit 1

# Variables
SECRET_NAME="$1" # Nombre del secreto inicial

# Funciones de instalación y configuración
instalar_awscli() {
  echo "Instalando AWS CLI..."
  ./instalar_awscli.sh
}

instalar_mqtt() {
  echo "Instalando Mosquitto..."
  ./instalar_mqtt.sh "$SECRET_NAME"
}

configurar_cron_limpieza() {
  echo "Configurando cron de limpieza de logs..."
  ./configurar_cron.sh "$SECRET_NAME"
}

configurar_logrotate() {
  echo "Configurando Logrotate..."
  ./configurar_logrotate.sh
}

configurar_cron_monitoreo() {
  echo "Configurando cron de monitoreo de Mosquitto..."
  ./configurar_mosquito_health.sh "$SECRET_NAME"
}

# Instalación de AWS CLI
instalar_awscli

# Instalación de Mosquitto
instalar_mqtt

# Configuración opcional
read -p "¿Desea configurar el cron de limpieza de logs? (s/n): " respuesta
if [ "$respuesta" == "s" ]; then
  configurar_cron_limpieza
fi

if [ "$respuesta" != "s" ]; then
    read -p "¿Desea configurar Logrotate? (s/n): " respuesta
    if [ "$respuesta" == "s" ]; then
    configurar_logrotate
    else
    echo "No configurar ningun mecanismo de limpieza de logs puede derivar en un uso excesivo de espacio de almacenamiento. Si el espacio de almacenamiento se agota, el servicio de Mosquitto MQTT dejara de funcionar"
    fi
fi

read -p "¿Desea configurar el cron de monitoreo de Mosquitto? (s/n): " respuesta
if [ "$respuesta" == "s" ]; then
  configurar_cron_monitoreo
else
    echo "No se ha configurado ningun monitoreo interno de estado de ejecucion de mosquitto MQTT. Se recomienda configurar mecanismos externos de verificacion de funcionamiento de mosquitto MQTT ejecutandose en este servidor"
fi

echo "Instalación inicial completada."