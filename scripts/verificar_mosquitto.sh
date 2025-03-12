#!/bin/bash
DIR_NAME=$(dirname "$0")
# Variables
SNS_TOPIC_FILE="/etc/mosquitto/sns_topic_arn.txt"
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

# Función para enviar alerta a SNS
enviar_alerta() {
  local mensaje="Alerta: El servicio Mosquitto ha fallado dos veces consecutivas en la instancia $INSTANCE_ID."
  "$DIR_NAME/enviar_log_cloudwatch.sh "MOSQUITTO-ERROR: El servicio Mosquitto ha fallado dos veces consecutivas en la instancia $INSTANCE_ID.""

  # Verificar archivo de script cron
    if [ ! -f "$SNS_TOPIC_FILE" ]; then
    echo "FAIL: No se encuentra el ARN de topico de alertas."
    $DIR_NAME/enviar_log_cloudwatch.sh "SNS-ALERT: No se encuentra el ARN de topico de alertas."
    exit 1
    fi

  aws sns publish --topic-arn "$(cat $SNS_TOPIC_FILE)" --message "$mensaje"
}

# Verificar estado de Mosquitto
if systemctl is-active mosquitto &> /dev/null; then
  echo "Mosquitto está en ejecución."
  exit 0
else
  echo "Mosquitto no está en ejecución. Intentando habilitarlo y reiniciarlo..."
  sudo systemctl enable mosquitto
  sudo systemctl restart mosquitto
  sleep 5 # Esperar a que Mosquitto se reinicie
  if systemctl is-active mosquitto &> /dev/null; then
    echo "Mosquitto habilitado y reiniciado correctamente."
    exit 0
  else
    echo "Fallo al habilitar y reiniciar Mosquitto. Enviando alerta..."
    enviar_alerta
    exit 1
  fi
fi

