#!/bin/bash
# 4.1 Verificar regla cron
CRON_RULE=$(crontab -l | grep "/etc/mosquitto/clean_mqtt_logs.sh")
if [ -z "$CRON_RULE" ]; then
  echo "FAIL: No se encuentra la regla cron para la limpieza de logs."
  exit 1
fi

# 4.2 Verificar archivo de script cron
if [ ! -f "/etc/mosquitto/clean_mqtt_logs.sh" ]; then
  echo "FAIL: No se encuentra el script de limpieza de logs."
  exit 1
fi

echo "SUCCESS"
exit 0