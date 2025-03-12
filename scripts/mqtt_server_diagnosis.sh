#!/bin/bash

# Funciones de verificación
verificar_aws() {
  local result=$($(dirname "$0")/verificar_aws.sh "$1")
  echo "$result"
  return 0
}

verificar_mqtt() {
  local result=$($(dirname "$0")/verificar_mqtt.sh "$1")
  echo "$result"
  return 0
}

verificar_cron() {
  local result=$($(dirname "$0")/verificar_cron.sh "$1")
  echo "$result"
  return 0
}

verificar_mqtt_cron() {
  local result=$($(dirname "$0")/verificar_mqtt_cron.sh "$1")
  echo "$result"
  return 0
}

verificar_logrotate () {
  local result=$($(dirname "$0")/verificar_lograte.sh "$1")
  echo "$result"
  return 0
}

# Funciones de instalación y configuración
instalar_aws_cli() {
  local result=$($(dirname "$0")/instalar_awscli.sh "$1")
  echo "$result"
  return 0
}

instalar_configurar_mqtt() {
  local result=$(sudo $(dirname "$0")/instalar_mqtt.sh "$1")
  echo "$result"
  return 0
}

configurar_cron() {
  local result=$($(dirname "$0")/configurar_cron.sh "$1")
  echo "$result"
  return 0
}

configurar_mqtt_cron() {
  local result=$($(dirname "$0")/configurar_mqtt_cron.sh "$1")
  echo "$result"
  return 0
}

configurar_logrotate() {
  local result=$($(dirname "$0")/configurar_logrotate.sh "$1")
  echo "$result"
  return 0
}

# Función principal
main() {
  # Verificar si se proporciona el argumento secret-name
  if [ -z "$1" ]; then
    echo "Error: Se debe proporcionar el argumento secret-name."
    exit 1
  fi
  SECRET_NAME="$1"

  # Variables para almacenar los resultados de las verificaciones
  AWS_RESULT="FAIL"
  MQTT_RESULT="FAIL"
  MQTT_CRON_RESULT="FAIL"
  CRON_RESULT="FAIL"
  LOGROTATE_RESULT="FAIL"

  # Verificaciones
  AWS_RESULT=$(verificar_aws "$SECRET_NAME")
  if [ "$AWS_RESULT" == "SUCCESS" ]; then
    MQTT_RESULT=$(verificar_mqtt)
    MQTT_CRON_RESULT=$(verificar_mqtt_cron)
  fi
	#if [ "$MQTT_RESULT" == "SUCCESS" ]; then
	  CRON_RESULT=$(verificar_cron)
	  LOGROTATE_RESULT=$(verificar_logrotate)
	#fi

  # Mostrar resultados
  echo "Resultado de la verificación de AWS: $AWS_RESULT"
  echo "Resultado de la verificación de MQTT: $MQTT_RESULT"
  echo "Resultado de la verificación de CRON REINICIO MQTT: $MQTT_CRON_RESULT"
  echo "Resultado de la verificación de CRON: $CRON_RESULT"
  echo "Resultado de la verificación de LOGROTATE: $LOGROTATE_RESULT"

  # Acciones basadas en los resultados
  if [ "$AWS_RESULT" != "SUCCESS" ]; then
    read -p "Desea instalar AWS CLI? (Y/n): " respuesta
    if [ "$respuesta" == "Y" ]; then
      instalar_aws_cli
      main "$SECRET_NAME" # Volver a ejecutar el diagnóstico
      return
    fi
  elif [ "$MQTT_RESULT" != "SUCCESS" ]; then
    read -p "Desea instalar y configurar MQTT? (Y/n): " respuesta
    if [ "$respuesta" == "Y" ]; then
      instalar_configurar_mqtt
      main "$SECRET_NAME" # Volver a ejecutar el diagnóstico
      return
    fi
  elif [ "$MQTT_CRON_RESULT" != "SUCCESS" ]; then
    read -p "Desea configurar cron de reinicio MQTT? (Y/n): " respuesta
    if [ "$respuesta" == "Y" ]; then
      configurar_mqtt_cron
      main "$SECRET_NAME" # Volver a ejecutar el diagnóstico
      return
    fi  
  elif [ "$CRON_RESULT" != "SUCCESS" ] && [ "$LOGROTATE_RESULT" != "SUCCESS" ]; then
    read -p "Desea configurar CRON o LOGROTATE? (cron/logrotate): " respuesta
    if [ "$respuesta" == "cron" ]; then
      configurar_cron
      main "$SECRET_NAME"
      return
    elif [ "$respuesta" == "logrotate" ]; then
      configurar_logrotate
      main "$SECRET_NAME"
      return
    fi
  fi
}

# Ejecutar la función principal
main "$@"