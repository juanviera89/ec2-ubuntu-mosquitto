#!/bin/bash

case "$1" in
  "reparar_permisos")
    chmod +x ./scripts/*.sh
    ;;
  "configurar_limpieza")
    ./scripts/configurar_cron.sh "$2"
    ;;
  "configurar_logrotate")
    ./scripts/configurar_logrotate.sh
    ;;
  "instalacion_inicial")
    ./scripts/instalacion_inicial.sh "$2"
    ;;
  "instalar_awscli")
    ./scripts/instalar_awscli.sh "$2"
    ;;
  "instalar_mqtt")
    ./scripts/instalar_mqtt.sh "$2"
    ;;
  "mqtt_update_config")
    ./scripts/mqtt_update_config.sh "$2"
    ;;
  "mqtt_update_pass")
    ./scripts/mqtt_update_pass.sh "$2"
    ;;
  "mqtt_server_diagnosis")
    ./scripts/mqtt_server_diagnosis.sh "$2"
    ;;
  "configurar_monitor")
    ./scripts/configurar_mosquito_health.sh "$2"
    ;;
  "configurar_reinicio")
    ./scripts/configurar_mqtt_cron.sh "$2"
    ;;
  *)
    echo "Uso: $0 {reparar_permisos|configurar_limpieza|configurar_logrotate|instalacion_inicial|instalar_awscli|instalar_mqtt|mqtt_update_config|mqtt_update_pass|mqtt_server_diagnosis|configurar_monitor|configurar_reinicio} [secret-name-inicial]"
    exit 1
    ;;
esac