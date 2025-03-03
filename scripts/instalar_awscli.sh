#!/bin/bash

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
exit 0