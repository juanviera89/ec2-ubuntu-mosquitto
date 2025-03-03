#!/bin/bash

echo "Instalando AWS CLI..."

# Verificar si curl y unzip están instalados
if ! command -v curl &> /dev/null || ! command -v unzip &> /dev/null; then
  sudo apt update
  sudo apt install curl unzip -y
fi

# Actualizar paquetes
sudo apt update

# Descargar AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# Descomprimir el archivo
unzip awscliv2.zip

# Ejecutar el instalador
sudo ./aws/install

# Verificar instalación
if ! command -v aws &> /dev/null; then
  echo "Error: AWS CLI no se instaló correctamente."
  exit 1
fi

# Verificar la instalación
aws --version

echo "AWS CLI instalado correctamente."
exit 0