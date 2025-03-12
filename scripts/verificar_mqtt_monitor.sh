#!/bin/bash
# 4.1 Verificar regla cron
CRON_RULE=$(crontab -l | grep "verificar_mosquitto.sh")
if [ -z "$CRON_RULE" ]; then
  echo "FAIL: No se encuentra la regla cron monitor de MQTT."
  exit 1
fi

echo "SUCCESS"
exit 0