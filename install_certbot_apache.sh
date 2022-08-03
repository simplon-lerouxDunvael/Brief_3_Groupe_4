#!/bin/bash
sudo su -
apt-get update -y
apt-get upgrade -y
apt-get install wget apache2 snapd -y
snap install core; sudo snap refresh core
snap install --classic certbot

ln -s /snap/bin/certbot /usr/bin/certbot
chown -R www-data:www-data 

echo "Listen 8080
<VirtualHost *:8080>

	ServerAdmin simplon.nicolasmarty@gmail.com
    ServerName $1.$2.cloudapp.azure.com
	DocumentRoot /var/www/html

	ErrorLog ${APACHE_LOG_DIR}/error.log
	CustomLog ${APACHE_LOG_DIR}/access.log combined

SSLEngine on
SSLCertificateFile /etc/letsencrypt/live/$1.$2.cloudapp.azure.com/fullchain.pem
SSLCertificateKeyFile /etc/letsencrypt/live/$1.$2.cloudapp.azure.com/privkey.pem

RewriteEngine on
RewriteCond %{SERVER_NAME} =$1.$2.cloudapp.azure.com
RewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [END,NE,R=permanent]
</VirtualHost>">/etc/apache2/sites-available/000-default.conf

echo "<IfModule mod_ssl.c>
<VirtualHost *:443>

	ServerAdmin simplon.nicolasmarty@gmail.com
    ServerName $1.$2.cloudapp.azure.com
	DocumentRoot /var/www/html

	ErrorLog ${APACHE_LOG_DIR}/error.log
	CustomLog ${APACHE_LOG_DIR}/access.log combined

SSLEngine on
SSLCertificateFile /etc/letsencrypt/live/$1.$2.cloudapp.azure.com/fullchain.pem
SSLCertificateKeyFile /etc/letsencrypt/live/$1.$2.cloudapp.azure.com/privkey.pem

RewriteEngine on
RewriteCond %{SERVER_NAME} =$1.$2.cloudapp.azure.com
RewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [END,NE,R=permanent]
</VirtualHost>
</IfModule>">>/etc/apache2/sites-available/000-default-ssl.conf

mkdir /var/log/apache2
chown -R /var/log/apache2
certbot --apache --non-interactive --agree-tos --redirect -m simplon.nicolasmarty@gmail.com -d "$1"."$2".cloudapp.azure.com

/etc/init.d/apache2 start
