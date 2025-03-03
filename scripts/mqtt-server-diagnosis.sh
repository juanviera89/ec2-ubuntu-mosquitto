#!/bin/bash

# Funciones de verificación
verificar_aws() {
  local result=$(./verificar_aws.sh "$1")
  echo "$result"
  return "$result"
}

verificar_mqtt() {
  local result=$(./verificar_mqtt.sh "$1")
  echo "$result"
  return "$result"
}

verificar_cron() {
  local result=$(./verificar_cron.sh "$1")
  echo "$result"
  return "$result"
}

verificar_logrotate () {
  local result=$(./verificar_lograte.sh "$1")
  echo "$result"
  return "$result"
}

# Funciones de instalación y configuración
instalar_aws_cli() {
  local result=$(./instalar_awscli.sh "$1")
  echo "$result"
  return "$result"
}

instalar_configurar_mqtt() {
  local result=$(./instalar_mqtt.sh "$1")
  echo "$result"
  return "$result"
}

configurar_cron() {
  local result=$(./configurar_cron.sh "$1")
  echo "$result"
  return "$result"
}

configurar_logrotate() {
  local result=$(./configurar_logrotate.sh "$1")
  echo "$result"
  return "$result"
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
  CRON_RESULT="FAIL"
  LOGROTATE_RESULT="FAIL"

  # Verificaciones
  AWS_RESULT=$(verificar_aws "$SECRET_NAME")
  if [ "$AWS_RESULT" == "SUCCESS" ]; then
    MQTT_RESULT=$(verificar_mqtt)
  fi
	#if [ "$MQTT_RESULT" == "SUCCESS" ]; then
	  CRON_RESULT=$(verificar_cron)
	  LOGROTATE_RESULT=$(verificar_logrotate)
	#fi

  # Mostrar resultados
  echo "Resultado de la verificación de AWS: $AWS_RESULT"
  echo "Resultado de la verificación de MQTT: $MQTT_RESULT"
  echo "Resultado de la verificación de CRON: $CRON_RESULT"

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