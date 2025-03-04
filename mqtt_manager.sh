#!/bin/bash
chmod +x ./scripts/*.sh
case "$1" in
  "configurar_cron")
    ./configurar_cron.sh
    ;;
  "configurar_logrotate")
    ./configurar_logrotate.sh
    ;;
  "configurar_mosquito_health")
    ./configurar_cron_mosquitto.sh "$2"
    ;;
  "instalacion_inicial")
    ./instalacion_inicial.sh "$2"
    ;;
  "instalar_awscli")
    ./instalar_awscli.sh
    ;;
  "instalar_mqtt")
    ./instalar_mqtt.sh "$2"
    ;;
  "mqtt_update_config")
    ./mqtt_update_config.sh
    ;;
  "mqtt_update_pass")
    ./mqtt_update_pass.sh
    ;;
  "mqtt-server-diagnosis")
    ./mqtt-server-diagnosis.sh "$2"
    ;;
  *)
    echo "Uso: $0 {configurar_cron|configurar_logrotate|configurar_mosquito_health|instalacion_inicial|instalar_awscli|instalar_mqtt|mqtt_update_config|mqtt_update_pass|mqtt-server-diagnosis} [secret-name-inicial]"
    exit 1
    ;;
esac