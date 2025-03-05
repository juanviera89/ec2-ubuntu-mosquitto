#!/bin/bash

# Variables
LOG_MESSAGE="$1"
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/[a-z]$//')
source "$(dirname "$0")/instance_role.sh" # Obtener credenciales de instancia
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
LOG_GROUP_NAME="mosquitto-$INSTANCE_ID"
LOG_STREAM_NAME="ec2-mqtt-$(date +%Y-%m-%d)"
TIMESTAMP=$(date +%s%3N) # Timestamp en milisegundos

# Función para crear grupo de logs si no existe
crear_log_group() {
  if aws logs describe-log-groups --log-group-name-prefix "$LOG_GROUP_NAME" --query "logGroups[].logGroupName" --output text | grep -q "$LOG_GROUP_NAME"; then
    echo "Grupo de logs $LOG_GROUP_NAME ya existe."
  else
    aws logs create-log-group --log-group-name "$LOG_GROUP_NAME" --retention-in-days 7 # Retención de 7 días
    if [ $? -ne 0 ]; then
      echo "Error al crear el grupo de logs $LOG_GROUP_NAME."
      exit 1
    fi
    echo "Grupo de logs $LOG_GROUP_NAME creado correctamente."
  fi
}

# Función para crear flujo de logs si no existe
crear_log_stream() {
  if aws logs describe-log-streams --log-group-name "$LOG_GROUP_NAME" --log-stream-name-prefix "$LOG_STREAM_NAME" --query "logStreams[].logStreamName" --output text | grep -q "$LOG_STREAM_NAME"; then
    echo "Flujo de logs $LOG_STREAM_NAME ya existe."
  else
    aws logs create-log-stream --log-group-name "$LOG_GROUP_NAME" --log-stream-name "$LOG_STREAM_NAME"
    if [ $? -ne 0 ]; then
      echo "Error al crear el flujo de logs $LOG_STREAM_NAME."
      exit 1
    fi
    echo "Flujo de logs $LOG_STREAM_NAME creado correctamente."
  fi
}

# Crear grupo de logs y flujo de logs
crear_log_group
crear_log_stream

# Enviar log a CloudWatch Logs
aws logs put-log-events --log-group-name "$LOG_GROUP_NAME" --log-stream-name "$LOG_STREAM_NAME" --log-events timestamp="$TIMESTAMP",message="$LOG_MESSAGE"

if [ $? -ne 0 ]; then
  echo "Error al enviar el log a CloudWatch Logs."
  exit 1
fi

echo "Log enviado a CloudWatch Logs correctamente."
exit 0