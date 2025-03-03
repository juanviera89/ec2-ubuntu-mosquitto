#!/bin/bash

LOG_DIR="/mosquitto/tracing/logs"
DAYS_TO_KEEP=7

# Verificar si el directorio existe
if [ ! -d "$LOG_DIR" ]; then
  echo "Error: El directorio $LOG_DIR no existe."
  exit 1
fi

# Encontrar y eliminar archivos antiguos
find "$LOG_DIR" -type f -mtime +"$DAYS_TO_KEEP" -delete

# Mensaje de confirmación (opcional)
echo "Archivos de logs antiguos eliminados de $LOG_DIR"