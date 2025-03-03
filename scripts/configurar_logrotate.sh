#!/bin/bash
echo "Configurando Logrotate para Mosquitto..."

# Crear archivo de configuración
echo "/mosquitto/logs/mosquitto.log* {
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