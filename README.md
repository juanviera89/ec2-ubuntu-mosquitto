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
## Preparacion de instancia

1. Instancia debe ser basada en Ubuntu 24 o superior
2. Debe tener un perfil cuya politica de permisos contenga al menos los siguientes permisos:
  ```json
  {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Sid": "VisualEditor0",
              "Effect": "Allow",
              "Action": [
                  "sts:AssumeRole",
                  "secretsmanager:GetSecretValue",
                  "secretsmanager:DescribeSecret",
                  "sns:Publish",
                  "sns:GetTopicAttributes",
                  "logs:DescribeLogStreams",
                  "logs:GetLogEvents",
                  "logs:CreateLogGroup",
                  "logs:ListTagsLogGroup",
                  "logs:CreateLogStream",
                  "logs:GetLogRecord",
                  "logs:PutRetentionPolicy",
                  "logs:PutLogEvents"
              ],
              "Resource": [
                  "arn:aws:iam::879381280001:role/ec2-mqtt-elevated-rol",
                  "arn:aws:secretsmanager:us-east-1:879381280001:secret:prod/mqtt/rol-c9Y5Pk",
                  "arn:aws:logs:us-east-1:879381280001:log-group:ec2-mqtt-*",
                  "arn:aws:logs:us-east-1:879381280001:log-group:arn:aws:logs:us-east-1:879381280001:log-group:ec2-mqtt-*:log-stream:mosquitto-*",
                  "arn:aws:sns:us-east-1:879381280001:CloudWatch_Alarms_TgtGrp_min_instances"
              ]
          },
          {
              "Sid": "VisualEditor1",
              "Effect": "Allow",
              "Action": [
                  "sts:GetSessionToken",
                  "sts:GetAccessKeyInfo",
                  "sts:GetCallerIdentity",
                  "sts:GetServiceBearerToken",
                  "sns:ListTopics",
                  "logs:DescribeLogGroups"
              ],
              "Resource": "*"
          }
      ]
  }
  ```
  El roldebe estar asociado a la instancia. Se sugiere; por buenas practivas de seguridad;  que el rol solo pueda ser asumido por instancias de EC2. Se puede aplicar relacion de confianza al rol:
  ```json
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
  }
  ```
3. El grupo de seguridad asociado debe permitir ingress SSH desde la instancia bastion, y permitir TCP en el puerto configurado para mqtt desde el balanceador de carga. Se sugiere; por buenas practivas de seguridad; desactivar la asignacion de ip publica automatica y que la regla de ingress de MQTT sea solo desde el balanceador o redes internas.
4. Puede aplicar comprobacion de estado en el grupo destino, usando comprobacion TCP al puerto de trafico
5. Se sugiere que el agente de escucha del balanceador de carga sea de tipo TLS para delegar el trabajo de cifrado al balanceador y mantener la conexion segura entre el servicio y los clientes.
6. El grupo de seguridad del balanceador de carga debe permitir conexiones entrantes en el puerto del agente de escucha creado para el servidor mqtt



## Instalación y configuración
- Clona este repositorio en tu instancia EC2.
- Navega al directorio del repositorio.
- Aplica el comando `chmod +x ./mqtt_manager.sh` y posteriormente `./mqtt_manager.sh reparar_permisos`
- Ejecuta la instalacion inicial aplicando `sudo ./mqtt_manager.sh instalacion_inicial ec2-secreto-inicial`. ec2-secreto-inicial es el nombre del secreto base que contiene el arn del rol elevado, el nombre o ARN del secreto que contiene la configuracion de MQTT y el ARN del topico SNS para alertas

Si la instalacion inicial falla en iniciar mosquitto, ejecute el comando `sudo systemctl restart mosquitto.service` y luego ` systemctl status mosquitto.service` para verificar que se encuentre en ejecucion correctamente

Puede intentar instalar mqtt nuevamente usando `sudo ./mqtt_manager.sh instalar_mqtt ec2-secreto-inicial`

## Diagnóstico
Ejecuta el script `./mqtt_manager.sh mqtt_server_diagnosis ec2-secreto-inicial`. ec2-secreto-inicial es el nombre del secreto base que contiene el arn del rol elevado, el nombre o ARN del secreto que contiene la configuracion de MQTT y el ARN del topico SNS para alertas.

Este script realizará las siguientes verificaciones:

1. AWS CLI instalada y configurada.
2. Servicio Mosquitto instalado y en ejecución.
3. Archivo de configuración de Mosquitto presente.
4. Archivo de contraseñas de Mosquitto presente.
5. Cronjob de verificación de Mosquitto configurado (opcional).
6. Rotación de logs configurada (opcional).

El script te dará la opción de instalar o configurar los componentes que no estén configurados correctamente.

## Scripts adicionales

- reparar_permisos: Aplica permisos de ejecucion para los scripts de administracion. Sin los permisos adecuados, ejecutar cualquier comando de mqtt_manager indicara error de permiso o script no encontrado
- configurar_cron: Configura un CRON para eliminar logs. Es mas estricto que logrotate dado que elimina todos los archivos en un directorio, que hayan sido creados anterior a 7 dias. La periodicidad es configurada a partir del valor de `mqtt-clean-cron` en el secreto de configuracion mqtt.  (Rquiere argumento ec2-secreto-inicial)
- configurar_logrotate: Configura logrotate, una herramienta eficiente que comprime logs pasados cierta fecha para disminuir el consumo de almacenamiento, y tambien elimina logs con mucho mas tiempo para liberar espacio.
- configurar_mosquito_health: Configura un CRON de monitoreo de estado de ejecucion del servicio MQTT. En caso de fallo envia notificacion al topico configurado en "ec2-secreto-inicial" y genera logs en Cloudwatch.  (Rquiere argumento ec2-secreto-inicial)
- instalar_awscli: Instala la consola de comandos de AWS, requerida para la todos los procesos de configuracion y monitoreo.
- instalar_mqtt: Instala el servicio MQTT usando Eclipse mosquitto. Las configuraciones a aplicar seran las almacenadas en el secreto de configuraciones MQTT. (Rquiere argumento ec2-secreto-inicial)
- mqtt_update_config: Actualiza la configuración de Mosquitto . (Rquiere argumento ec2-secreto-inicial)
- mqtt_update_pass: Actualiza el archivo de contraseñas de Mosquitto. (Rquiere argumento ec2-secreto-inicial)


# Notas
- Los scripts deben ser ejecutados desde cuenta Root
- Asegúrate de reemplazar los valores de los marcadores de posición (TU_CUENTA, TU_REGION, etc.) con los valores reales de tu entorno.
- Los scripts asumen que se ejecutan en una instancia EC2 de Ubuntu con los permisos de IAM adecuados.
- Las contraseñas de mosquitto deben tener el formato username:password. Donde cada usuario debe ser una linea diferente y la contraseña debe ser en texto plano, posteriormente las mismas seran encriptadas por el proceso de actualizacion/configuracion de conttrtaseñas 
- el archivo de [ejemplo de configuracion](./resources/mosquitto.conf) es un ejemplo funcional de un archivo de configuracion, comentado para facilitar el ajuste de configuraciones. Se sugiere eliminar los comentarios antes de almacenar la configuracion en Secret manager
- La configuracion debe ser almacenada en texto plano en secret manager, por lo que debe aplicar caracter de salto de line \\n para cada linea
 
Fuentes y contenido relacionado
- [mosquitto.conf](https://mosquitto.org/man/mosquitto-conf-5.html)
- [mosquitto_passwd](https://mosquitto.org/man/mosquitto_passwd-1.html#)
- [Create secrent in secret manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/create_secret.html)

## Ejemplos de secretos para secret manager

- ec2-secreto-inicial:
```json
{
  "elevated-rol":"arn:aws:iam::AWS-ACCOUNT-ID:role/ELEVATED-ROLE-NAME",
  "mqtt-config-secret":"arn:aws:secretsmanager:REGION:AWS-ACCOUNT-ID:secret:prod/MQTT-CONFIG-SECRET-NAME",
  "sns_topic_arn":"arn:aws:sns:REGION:AWS-ACCOUNT-ID:SNS-TOPIC-NAME"
}
```
- MQTT-CONFIG-SECRET-NAME:
```json
{
  "mqtt-pass":"snappmqtt:thisisanicepassword",
  "mqtt-conf":"port 9883\nallow_anonymous false\nallow_zero_length_clientid true\npassword_file /etc/mosquitto/pass.txt\nsys_interval 60\npersistence true\nmax_packet_size 10240\nmax_keepalive 60\npersistent_client_expiration 1m\n",
  "mqtt-clean-cron":"0 6 * * *"
}
```