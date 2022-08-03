#!/bin/bash
sudo su -
apt-get update -y
apt-get upgrade -y
apt-get install wget apache2 snapd -y
snap install core; sudo snap refresh core
snap install --classic certbot
a2enmod rewrite ssl proxy proxy_http headers
ln -s /snap/bin/certbot /usr/bin/certbot
mkdir /var/log/apache2
chown -R www-data:www-data /var/log/apache2
systemctl stop apache2
certbot certonly --standalone --non-interactive --agree-tos --redirect -m simplon.nicolasmarty@gmail.com -d $1.$2.cloudapp.azure.com
echo "<VirtualHost *:80>

	ServerAdmin simplon.nicolasmarty@gmail.com
    ServerName $1.$2.cloudapp.azure.com
	DocumentRoot /var/www/html


	ErrorLog ${APACHE_LOG_DIR}/error.log
	CustomLog ${APACHE_LOG_DIR}/access.log combined


# redirige vers le https
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

	ProxyPass "/" "http://127.0.0.1:8080/"
	ProxyPassReverse "/" "http://127.0.0.1:8080/"
</VirtualHost>
</IfModule>">/etc/apache2/sites-available/000-default-ssl.conf
a2ensite 000-default-ssl
systemctl start apache2
