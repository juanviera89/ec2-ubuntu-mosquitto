# Configuración de Mosquitto en EC2

Este documento describe cómo configurar un servidor Mosquitto en una instancia EC2 de Ubuntu utilizando los scripts proporcionados.

## Requisitos previos

*   Una instancia EC2 de Ubuntu en funcionamiento.
*   Un rol de IAM con permisos para:
    *   Acceder a Secrets Manager.
    *   Asumir un rol elevado.
    *   Publicar en temas de SNS (opcional, para alertas).
    *   Escribir logs en CloudWatch Logs (opcional, para registro de eventos).
*   Un secreto en AWS Secrets Manager con la siguiente estructura:

```json
{
  "elevated-rol": "arn:aws:iam::TU_CUENTA:role/TU_ROL_ELEVADO",
  "mqtt-config-secret": "arn:aws:secretsmanager:TU_REGION:TU_CUENTA:secret:TU_SECRETO_CONFIG_MQTT",
  "sns_topic_arn": "arn:aws:sns:TU_REGION:TU_CUENTA:TU_TOPICO_SNS"
}
```

```json
{
  "mqtt-conf": "TU_CONFIGURACION_MOSQUITTO -> se almacenara en formato plano en el archivo mosquitto.conf",
  "mqtt-pass": "TU_LISTA_DE_USUARIOS_Y_CONTRASENIAS -> se almacenara en formato plano en el archivo de passwords a ser usado por mosquitto.",
  "mqtt-clean-cron": "Expresion CRON para definir periodicidad de limpieza de logs"
}
```

## Instalación y configuración
Clona este repositorio en tu instancia EC2.
Navega al directorio del repositorio.
aplica el comando `chmod +x ./mqtt_manager.sh`
Ejecuta la instalacion inicial aplicando `./mqtt_manager.sh instalacion_inicial ec2-secreto-inicial`. ec2-secreto-inicial es el nombre del secreto base que contiene el arn del rol elevado, el nombre o ARN del secreto que contiene la configuracion de MQTT y el ARN del topico SNS para alertas

## Diagnóstico
Ejecuta el script `./mqtt_manager.sh mqtt-server-diagnosis ec2-secreto-inicial`. ec2-secreto-inicial es el nombre del secreto base que contiene el arn del rol elevado, el nombre o ARN del secreto que contiene la configuracion de MQTT y el ARN del topico SNS para alertas.

Este script realizará las siguientes verificaciones:

1. AWS CLI instalada y configurada.
2. Servicio Mosquitto instalado y en ejecución.
3. Archivo de configuración de Mosquitto presente.
4. Archivo de contraseñas de Mosquitto presente.
5. Cronjob de verificación de Mosquitto configurado (opcional).
6. Rotación de logs configurada (opcional).

El script te dará la opción de instalar o configurar los componentes que no estén configurados correctamente.

## Scripts adicionales


- configurar_cron: Configura un CRON para eliminar logs. Es mas estricto que logrotate dado que elimina todos los archivos en un directorio, que hayan sido creados anterior a 7 dias. La periodicidad es configurada a partir del valor de `mqtt-clean-cron` en el secreto de configuracion mqtt.  (Rquiere argumento ec2-secreto-inicial)
- configurar_logrotate: Configura logrotate, una herramienta eficiente que comprime logs pasados cierta fecha para disminuir el consumo de almacenamiento, y tambien elimina logs con mucho mas tiempo para liberar espacio.
- configurar_mosquito_health: Configura un CRON de monitoreo de estado de ejecucion del servicio MQTT. En caso de fallo envia notificacion al topico configurado en "ec2-secreto-inicial" y genera logs en Cloudwatch.  (Rquiere argumento ec2-secreto-inicial)
- instalar_awscli: Instala la consola de comandos de AWS, requerida para la todos los procesos de configuracion y monitoreo.
- instalar_mqtt: Instala el servicio MQTT usando Eclipse mosquitto. Las configuraciones a aplicar seran las almacenadas en el secreto de configuraciones MQTT. (Rquiere argumento ec2-secreto-inicial)
- mqtt_update_config: Actualiza la configuración de Mosquitto . (Rquiere argumento ec2-secreto-inicial)
- mqtt_update_pass: Actualiza el archivo de contraseñas de Mosquitto. (Rquiere argumento ec2-secreto-inicial)


# Notas
- Asegúrate de reemplazar los valores de los marcadores de posición (TU_CUENTA, TU_REGION, etc.) con los valores reales de tu entorno.
- Los scripts asumen que se ejecutan en una instancia EC2 de Ubuntu con los permisos de IAM adecuados.
- Las contraseñas de mosquitto deben tener el formato username:hashpass. Donde cada usuario debe ser una linea diferente y la contraseña debe ser en texto plano, posteriormente las mismas seran encriptadas por el proceso de actualizacion/configuracion de conttrtaseñas 
- el archivo de [ejemplo de configuracion](./resources/mosquitto.conf) es un ejemplo funcional de un archivo de configuracion, comentado para facilitar el ajuste de configuraciones
 
Fuentes y contenido relacionado
- [mosquitto.conf](https://mosquitto.org/man/mosquitto-conf-5.html)
- [mosquitto_passwd](https://mosquitto.org/man/mosquitto_passwd-1.html#)
- [Create secrent in secret manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/create_secret.html)