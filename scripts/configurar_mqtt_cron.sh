#!/bin/bash
echo "Configurando CRON..."

# 7. Configurar cron como root
CRON_LINE="0 5 * * * sudo systemctl restart mosquitto"
CRON_EXIST=$(sudo crontab -l | grep "sudo systemctl restart mosquitto")

if [ -n "$CRON_EXIST" ]; then
sudo crontab -l | grep -v "sudo systemctl restart mosquitto" | sudo crontab -
fi

(sudo crontab -l 2>/dev/null; echo "$CRON_LINE") | sudo crontab -

echo "CRON configurado como root correctamente."
exit 0