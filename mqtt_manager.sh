#!/bin/bash

case "$1" in
  "reparar_permisos")
    chmod +x ./scripts/*.sh
    ;;
  "configurar_cron")
    ./scripts/configurar_cron.sh
    ;;
  "configurar_logrotate")
    ./scripts/configurar_logrotate.sh
    ;;
  "configurar_mosquito_health")
    ./scripts/configurar_cron_mosquitto.sh "$2"
    ;;
  "instalacion_inicial")
    ./scripts/instalacion_inicial.sh "$2"
    ;;
  "instalar_awscli")
    ./scripts/instalar_awscli.sh
    ;;
  "instalar_mqtt")
    ./scripts/instalar_mqtt.sh "$2"
    ;;
  "mqtt_update_config")
    ./scripts/mqtt_update_config.sh
    ;;
  "mqtt_update_pass")
    ./scripts/mqtt_update_pass.sh
    ;;
  "mqtt-server-diagnosis")
    ./scripts/mqtt-server-diagnosis.sh "$2"
    ;;
  *)
    echo "Uso: $0 {configurar_cron|configurar_logrotate|configurar_mosquito_health|instalacion_inicial|instalar_awscli|instalar_mqtt|mqtt_update_config|mqtt_update_pass|mqtt-server-diagnosis} [secret-name-inicial]"
    exit 1
    ;;
esac