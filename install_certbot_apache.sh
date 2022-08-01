sudo su -
apt-get update -y
apt-get install apache2 -y 
systemctl enable apache2
apt-get install certbot
ln -s /snap/bin/certbot /usr/bin/certbot 
certbot --apache
echo " SSLEngine on">>/etc/apache2/sites-enabled/000-default.conf
