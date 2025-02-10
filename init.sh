#!/bin/bash

# MIT License
#
# Copyright (c) 2025 mgrl39
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No color

# Check if the user is root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Este script debe ejecutarse como usuario: ${YELLOW}root${NC}"
    exit 1
fi

# Display license information and installation details
echo -e "${BLUE}==============================================================================${NC}"
echo -e "${YELLOW}Este script instalará los siguientes componentes:${NC}"
echo -e "${GREEN}- OpenSSH Server${NC}"
echo -e "${GREEN}- Apache Web Server${NC}"
echo -e "${GREEN}- PHP y MySQL${NC}"
echo -e "${GREEN}- Configuración del dominio local (www.fungi.local)${NC}"
echo -e "${BLUE}==============================================================================${NC}"
echo -e "${YELLOW}Al continuar, aceptas los términos de la Licencia MIT.${NC}"
echo -e "${BLUE}==============================================================================${NC}"

# Ask for confirmation
read -p "¿Deseas continuar con la instalación? (y/N): " response
if [[ "$response" != "y" && "$response" != "Y" ]]; then
    echo -e "${RED}Instalación cancelada.${NC}"
    exit 0
fi

# Installation process
echo -e "${GREEN}Actualizando sistema...${NC}"
apt update -y > /dev/null 2>&1

echo -e "${GREEN}Instalando OpenSSH Server...${NC}"
apt install openssh-server -y > /dev/null 2>&1

echo -e "${GREEN}Instalando Apache...${NC}"
apt install apache2 -y > /dev/null 2>&1

echo -e "${GREEN}Permitiendo SSH en UFW...${NC}"
ufw allow in "ssh" > /dev/null 2>&1

echo -e "${GREEN}Permitiendo Apache en UFW...${NC}"
ufw allow in "Apache" > /dev/null 2>&1

echo -e "${GREEN}Habilitando UFW...${NC}"
ufw --force enable > /dev/null 2>&1

echo -e "${GREEN}Instalando PHP y MySQL...${NC}"
apt install php libapache2-mod-php php-mysql mysql-server -y > /dev/null 2>&1

# Create necessary directories
if [ ! -d "/var/www/html/" ]; then
    echo -e "${GREEN}Creando directorio /var/www/html...${NC}"
    mkdir -p /var/www/html
fi

# Add entry to /etc/hosts
ETCHOSTS=$(grep "www.fungi.local" /etc/hosts)
if [ -z "$ETCHOSTS" ]; then
    echo -e "${GREEN}Añadiendo www.fungi.local a /etc/hosts...${NC}"
    echo -e "###### Fungi ######\n127.0.0.1\twww.fungi.local\n###### Fungi ######" >> /etc/hosts
fi

# Create website directory and test file
echo -e "${GREEN}Creando directorio /var/www/fungi.local/public...${NC}"
mkdir -p /var/www/fungi.local/public
echo "<?php phpinfo(); ?>" > /var/www/fungi.local/public/index.php

# Configure Apache virtual host
echo -e "${GREEN}Configurando sitio Apache para fungi.local...${NC}"
cat <<EOF > /etc/apache2/sites-available/fungi.local.conf
<VirtualHost *:80>
    ServerAdmin admin@fungi.local
    ServerName www.fungi.local
    ServerAlias fungi.local
    DocumentRoot /var/www/fungi.local/public
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
    <Directory /var/www/fungi.local/public>
        AllowOverride All
    </Directory>
</VirtualHost>
EOF

# Enable the site and reload Apache
echo -e "${GREEN}Habilitando el sitio fungi.local...${NC}"
a2ensite fungi.local.conf > /dev/null 2>&1
systemctl reload apache2 > /dev/null 2>&1

# Final instructions
echo -e "${BLUE}==============================================================================${NC}"
echo -e "${YELLOW}¡Instalación completada!${NC}"
echo -e "${GREEN}Recuerda configurar MySQL ejecutando: ${YELLOW}mysql_secure_installation${NC}"
echo -e "${BLUE}==============================================================================${NC}"
