#!/bin/bash
# 4.1 Verificar regla cron
CRON_RULE=$(crontab -l | grep "sudo systemctl restart mosquitto")
if [ -z "$CRON_RULE" ]; then
  echo "FAIL: No se encuentra la regla cron para la reinicio de MQTT."
  exit 1
fi

echo "SUCCESS"
exit 0