#!/bin/bash
# 3.1 Verificar mosquitto
  if ! command -v mosquitto &> /dev/null; then
    echo "FAIL: Mosquitto no está instalado."
    exit 1
  fi

# 3.1.1 Verificar si mosquitto esta habilitado
  if ! systemctl is-enabled mosquitto &> /dev/null; then
	echo "FAIL: El servicio Mosquitto no está habilitado."
	exit 1
  fi
  # 3.2 Verificar servicio mosquitto
  if ! systemctl is-active mosquitto &> /dev/null; then
    echo "FAIL: El servicio Mosquitto no está en ejecución."
    exit 1
  fi

  # 3.3 Verificar archivo de configuración
  if [ ! -f "/etc/mosquitto/conf.d/mosquitto.conf" ]; then
    echo "FAIL: No se encuentra el archivo de configuración de Mosquitto."
    exit 1
  fi

  # 3.4 Verificar archivo de contraseñas
  if [ ! -f "/etc/mosquitto/pass.txt" ]; then
    echo "FAIL: No se encuentra el archivo de contraseñas de Mosquitto."
    exit 1
  fi

  echo "SUCCESS"
  exit 0