#!/bin/bash
echo "Configurando Logrotate para Mosquitto..."

# Verificar si logrotate está instalado
if ! command -v logrotate &> /dev/null; then
  echo "Advertencia: Logrotate no está instalado. Intentando instalarlo..."
  sudo apt update
  sudo apt install logrotate -y
  if ! command -v logrotate &> /dev/null; then
    echo "Error: No se pudo instalar Logrotate."
    exit 1
  fi
  echo "Logrotate instalado correctamente."
fi
# Verificar si el directorio de logs existe
if [ ! -d "/var/log/mosquitto" ]; then
  echo "Error: El directorio /var/log/mosquitto no existe."
  exit 1
fi
# Crear archivo de configuración
echo "/var/log/mosquitto/mosquitto.log* {
    daily
    rotate 21
    maxage 7
    delaycompress
    compress
    compresscmd /usr/bin/gzip
    uncompresscmd /usr/bin/gunzip
    missingok
    notifempty
}" | sudo tee /etc/logrotate.d/mosquitto

echo "Logrotate configurado correctamente."