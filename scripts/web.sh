#!/bin/bash

# Verif si le fichier de conf apache à copier existe bien
if [[ ! -f /srv/conf_apache ]]; then
  echo "Le fichier de conf apache n'a pas été créé, créer le fichier /srv/conf_apache avec comme contenu la configuration en partie 2 de la partie 3 du tp5"
  exit 0
fi

sed -i 's/enforcing/permissive/g' /etc/selinux/config
setenforce 0
echo 'web.tp5.linux' | tee /etc/hostname

dnf install httpd -y > /dev/null
echo "serveur Apache installé avec succès"
systemctl enable httpd
systemctl start httpd

firewall-cmd --add-port=80/tcp --permanent > /dev/null
firewall-cmd --reload > /dev/null
echo "Port ouvert avec succès"

# Installation de php
dnf config-manager --set-enabled crb -y > /dev/null
dnf install dnf-utils http://rpms.remirepo.net/enterprise/remi-release-9.rpm -y > /dev/null
dnf module list php -y > /dev/null
dnf module enable php:remi-8.1 -y > /dev/null
dnf install -y php81-php > /dev/null
dnf install -y libxml2 openssl php81-php php81-php-ctype php81-php-curl php81-php-gd php81-php-iconv php81-php-json php81-php-libxml php81-php-mbstring php81-php-openssl php81-php-posix php81-php-session php81-php-xml php81-php-zip php81-php-zlib php81-php-pdo php81-php-mysqlnd php81-php-intl php81-php-bcmath php81-php-gmp > /dev/null
echo "PHP installé avec succès"

# Récupération du dossier nécéssaire à l'affichage du site NextCloud
mkdir /var/www/tp5_nextcloud/
curl https://download.nextcloud.com/server/prereleases/nextcloud-25.0.0rc3.zip -O > /dev/null
dnf install unzip -y > /dev/null
unzip nextcloud-25.0.0rc3.zip > /dev/null
mv nextcloud/* /var/www/tp5_nextcloud/
cd /var/www/tp5_nextcloud/
chown -R apache:apache .
echo "fichier tp5_nextcloud créé avec succès"

cp /srv/conf_apache /etc/httpd/conf.d/tp5_nextcloud.conf

systemctl restart httpd

echo "Installation et config d'Apache et mise en route de NextCloud réussies"
