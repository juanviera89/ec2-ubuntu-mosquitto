#!/bin/bash

# Funciones de verificación
verificar_aws() {
  # 2.1 Verificar AWS CLI
  if ! command -v aws &> /dev/null; then
    echo "FAIL: AWS CLI no está instalado."
    return "FAIL: AWS CLI no está instalado."
  fi

  # 2.2 Obtener credenciales de EC2
  INSTANCE_ROLE=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/ | jq -r 'keys[0]')
  CREDENTIALS=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/$INSTANCE_ROLE)
  if [ -z "$CREDENTIALS" ]; then
    echo "FAIL: No se pueden obtener las credenciales de EC2."
    return "FAIL: No se pueden obtener las credenciales de EC2."
  fi

  # 2.3 Leer secreto inicial
  SECRET_VALUE=$(aws secretsmanager get-secret-value --secret-id "$1" --query 'SecretString' --output text)
  if [ -z "$SECRET_VALUE" ]; then
    echo "FAIL: No se puede leer el secreto $1."
    return "FAIL: No se puede leer el secreto $1."
  fi

  # 2.4 Asumir rol elevado
  ELEVATED_ROLE=$(echo "$SECRET_VALUE" | jq -r '.elevated-rol')
  if [ -z "$ELEVATED_ROLE" ]; then
    echo "FAIL: No se encuentra el rol elevado en el secreto."
    return "FAIL: No se encuentra el rol elevado en el secreto."
  fi
  export AWS_ACCESS_KEY_ID=$(jq -r '.Credentials.AccessKeyId' <<< "$(aws sts assume-role --role-arn "$ELEVATED_ROLE" --role-session-name SesionCLI)")
  export AWS_SECRET_ACCESS_KEY=$(jq -r '.Credentials.SecretAccessKey' <<< "$(aws sts assume-role --role-arn "$ELEVATED_ROLE" --role-session-name SesionCLI)")
  export AWS_SESSION_TOKEN=$(jq -r '.Credentials.SessionToken' <<< "$(aws sts assume-role --role-arn "$ELEVATED_ROLE" --role-session-name SesionCLI)")

  # 2.5 Leer secreto MQTT
  MQTT_SECRET=$(echo "$SECRET_VALUE" | jq -r '.mqtt-config-secret')
  if [ -z "$MQTT_SECRET" ]; then
    echo "FAIL: No se encuentra el secreto MQTT en el secreto inicial."
    return "FAIL: No se encuentra el secreto MQTT en el secreto inicial."
  fi
  MQTT_SECRET_VALUE=$(aws secretsmanager get-secret-value --secret-id "$MQTT_SECRET" --query 'SecretString' --output text)
  if [ -z "$MQTT_SECRET_VALUE" ]; then
    echo "FAIL: No se puede leer el secreto MQTT $MQTT_SECRET."
    return "FAIL: No se puede leer el secreto MQTT $MQTT_SECRET."
  fi

  echo "SUCCESS"
  return "SUCCESS"
}

verificar_mqtt() {
  # 3.1 Verificar mosquitto
  if ! command -v mosquitto &> /dev/null; then
    echo "FAIL: Mosquitto no está instalado."
    return "FAIL: Mosquitto no está instalado."
  fi

# 3.1.1 Verificar si mosquitto esta habilitado
  if ! systemctl is-enabled mosquitto &> /dev/null; then
	echo "FAIL: El servicio Mosquitto no está habilitado."
	return "FAIL: El servicio Mosquitto no está habilitado."
  fi
  # 3.2 Verificar servicio mosquitto
  if ! systemctl is-active mosquitto &> /dev/null; then
    echo "FAIL: El servicio Mosquitto no está en ejecución."
    return "FAIL: El servicio Mosquitto no está en ejecución."
  fi

  # 3.3 Verificar archivo de configuración
  if [ ! -f "/mosquitto/config/mosquitto.conf" ]; then
    echo "FAIL: No se encuentra el archivo de configuración de Mosquitto."
    return "FAIL: No se encuentra el archivo de configuración de Mosquitto."
  fi

  # 3.4 Verificar archivo de contraseñas
  if [ ! -f "/mosquitto/config/pass.txt" ]; then
    echo "FAIL: No se encuentra el archivo de contraseñas de Mosquitto."
    return "FAIL: No se encuentra el archivo de contraseñas de Mosquitto."
  fi

  echo "SUCCESS"
  return "SUCCESS"
}

verificar_cron() {
  # 4.1 Verificar regla cron
  CRON_RULE=$(crontab -l | grep "/mosquitto/clean_mqtt_logs.sh")
  if [ -z "$CRON_RULE" ]; then
    echo "FAIL: No se encuentra la regla cron para la limpieza de logs."
    return "FAIL: No se encuentra la regla cron para la limpieza de logs."
  fi

  # 4.2 Verificar archivo de script cron
  if [ ! -f "/mosquitto/clean_mqtt_logs.sh" ]; then
    echo "FAIL: No se encuentra el script de limpieza de logs."
    return "FAIL: No se encuentra el script de limpieza de logs."
  fi

  echo "SUCCESS"
  return "SUCCESS"
}

verificar_logrotate () {
  # 3.6 Verificar logrotate y su configuración
  if ! command -v logrotate &> /dev/null; then
    echo "FAIL: Logrotate no está instalado."
    return "FAIL: Logrotate no está instalado."
  fi

  LOGROTATE_CONFIG=$(sudo cat /etc/logrotate.d/mosquitto 2>/dev/null | grep "/mosquitto/logs/mosquitto.log*")
  if [ -z "$LOGROTATE_CONFIG" ]; then
    echo "FAIL: Logrotate no está configurado para Mosquitto."
    return "FAIL: Logrotate no está configurado para Mosquitto."
  fi

  echo "SUCCESS"
  return "SUCCESS"
}

# Funciones de instalación y configuración
instalar_aws_cli() {

 echo "Instalando AWS CLI..."

  # Actualizar paquetes
  sudo apt update

  # Instalar dependencias
  sudo apt install zip unzip curl -y

  # Descargar AWS CLI
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

  # Descomprimir el archivo
  unzip awscliv2.zip

  # Ejecutar el instalador
  sudo ./aws/install

  # Verificar la instalación
  aws --version

  echo "AWS CLI instalado correctamente."
}

instalar_configurar_mqtt() {
  echo "Instalando y configurando Mosquitto..."

  # Instalar Mosquitto
  sudo apt update
  sudo apt install mosquitto mosquitto-clients -y

  # 1. Obtener credenciales de EC2
  INSTANCE_ROLE=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/ | jq -r 'keys[0]')
  CREDENTIALS=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/$INSTANCE_ROLE)
  ACCESS_KEY_ID=$(echo "$CREDENTIALS" | jq -r '.AccessKeyId')
  SECRET_ACCESS_KEY=$(echo "$CREDENTIALS" | jq -r '.SecretAccessKey')
  SESSION_TOKEN=$(echo "$CREDENTIALS" | jq -r '.Token')
  export AWS_ACCESS_KEY_ID=$ACCESS_KEY_ID
  export AWS_SECRET_ACCESS_KEY=$SECRET_ACCESS_KEY
  export AWS_SESSION_TOKEN=$SESSION_TOKEN

  # 2. Leer secreto inicial
  SECRET_VALUE=$(aws secretsmanager get-secret-value --secret-id "$1" --query 'SecretString' --output text)

  # 3. Asumir rol elevado
  ELEVATED_ROLE=$(echo "$SECRET_VALUE" | jq -r '.elevated-rol')
  export AWS_ACCESS_KEY_ID=$(jq -r '.Credentials.AccessKeyId' <<< "$(aws sts assume-role --role-arn "$ELEVATED_ROLE" --role-session-name SesionCLI)")
  export AWS_SECRET_ACCESS_KEY=$(jq -r '.Credentials.SecretAccessKey' <<< "$(aws sts assume-role --role-arn "$ELEVATED_ROLE" --role-session-name SesionCLI)")
  export AWS_SESSION_TOKEN=$(jq -r '.Credentials.SessionToken' <<< "$(aws sts assume-role --role-arn "$ELEVATED_ROLE" --role-session-name SesionCLI)")

  # 4. Leer secreto MQTT
  MQTT_SECRET=$(echo "$SECRET_VALUE" | jq -r '.mqtt-config-secret')
  MQTT_SECRET_VALUE=$(aws secretsmanager get-secret-value --secret-id "$MQTT_SECRET" --query 'SecretString' --output text)

  # 5. Escribir configuración de Mosquitto
  MQTT_CONF=$(echo "$MQTT_SECRET_VALUE" | jq -r '.mqtt-conf')
  echo "$MQTT_CONF" > "/mosquitto/config/mosquitto.conf"

  # 6. Escribir contraseñas de Mosquitto
  MQTT_PASS=$(echo "$MQTT_SECRET_VALUE" | jq -r '.mqtt-pass')
  echo "$MQTT_PASS" > "/mosquitto/config/pass.txt"

  # 7. Reiniciar Mosquitto
  sudo systemctl restart mosquitto

  echo "Mosquitto instalado y configurado correctamente."
  echo "Para mejor manejo de logs, se sugiere reemplazar el uso de cron de limpieza por la herramienta logrotate que puede ayudar a extender los tiempos almacenados, comprimiendo logs antiguos pero tambien eliminando los muy antiguos"
}

configurar_cron() {
  echo "Configurando CRON..."

  # 1. Obtener credenciales de EC2
  INSTANCE_ROLE=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/ | jq -r 'keys[0]')
  CREDENTIALS=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/$INSTANCE_ROLE)
  ACCESS_KEY_ID=$(echo "$CREDENTIALS" | jq -r '.AccessKeyId')
  SECRET_ACCESS_KEY=$(echo "$CREDENTIALS" | jq -r '.SecretAccessKey')
  SESSION_TOKEN=$(echo "$CREDENTIALS" | jq -r '.Token')
  export AWS_ACCESS_KEY_ID=$ACCESS_KEY_ID
  export AWS_SECRET_ACCESS_KEY=$SECRET_ACCESS_KEY
  export AWS_SESSION_TOKEN=$SESSION_TOKEN

  # 2. Leer secreto inicial
  SECRET_VALUE=$(aws secretsmanager get-secret-value --secret-id "$1" --query 'SecretString' --output text)

  # 3. Asumir rol elevado
  ELEVATED_ROLE=$(echo "$SECRET_VALUE" | jq -r '.elevated-rol')
  export AWS_ACCESS_KEY_ID=$(jq -r '.Credentials.AccessKeyId' <<< "$(aws sts assume-role --role-arn "$ELEVATED_ROLE" --role-session-name SesionCLI)")
  export AWS_SECRET_ACCESS_KEY=$(jq -r '.Credentials.SecretAccessKey' <<< "$(aws sts assume-role --role-arn "$ELEVATED_ROLE" --role-session-name SesionCLI)")
  export AWS_SESSION_TOKEN=$(jq -r '.Credentials.SessionToken' <<< "$(aws sts assume-role --role-arn "$ELEVATED_ROLE" --role-session-name SesionCLI)")

  # 4. Leer secreto MQTT
  MQTT_SECRET=$(echo "$SECRET_VALUE" | jq -r '.mqtt-config-secret')
  MQTT_SECRET_VALUE=$(aws secretsmanager get-secret-value --secret-id "$MQTT_SECRET" --query 'SecretString' --output text)

  # 5. Copiar script de limpieza y aplicar permisos
  cp ./clean_mqtt_logs.sh /mosquitto/clean_mqtt_logs.sh
  sudo chmod +x /mosquitto/clean_mqtt_logs.sh

  # 6. Leer configuración de cron
  MQTT_CRON=$(echo "$MQTT_SECRET_VALUE" | jq -r '.mqtt-clean-cron')
  if [ -z "$MQTT_CRON" ]; then
    echo "No hay cron configurado para limpieza."
    return
  fi

  # 7. Configurar cron como root
  CRON_LINE="$MQTT_CRON /mosquitto/clean_mqtt_logs.sh"
  CRON_EXIST=$(sudo crontab -l | grep "/mosquitto/clean_mqtt_logs.sh")

  if [ -n "$CRON_EXIST" ]; then
    sudo crontab -l | grep -v "/mosquitto/clean_mqtt_logs.sh" | sudo crontab -
  fi

  (sudo crontab -l 2>/dev/null; echo "$CRON_LINE") | sudo crontab -

  echo "CRON configurado como root correctamente."
}

configurar_logrotate() {
  echo "Configurando Logrotate para Mosquitto..."

  # Crear archivo de configuración
  echo "/mosquitto/logs/mosquitto.log* {
      daily
      rotate 21
      maxage 7
      delaycompress
      compress
      compresscmd /usr/bin/gzip
      uncompresscmd /usr/bin/gunzip
      missingok
      notifempty
  }" | sudo tee /etc/logrotate.d/mosquitto

  echo "Logrotate configurado correctamente."
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