#!/bin/bash

# 3.6 Verificar logrotate y su configuración
if ! command -v logrotate &> /dev/null; then
echo "FAIL: Logrotate no está instalado."
exit 1
fi

LOGROTATE_CONFIG=$(sudo cat /etc/logrotate.d/mosquitto 2>/dev/null | grep "/mosquitto/logs/mosquitto.log*")
if [ -z "$LOGROTATE_CONFIG" ]; then
echo "FAIL: Logrotate no está configurado para Mosquitto."
exit 1
fi

echo "SUCCESS"
exit 0