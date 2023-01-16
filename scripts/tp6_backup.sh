#!/bin/bash

# Sauvegarde des fichiers importants au fonctionnement de nextcloud et de la base de données nextcloud MariaDB pour backup

# noms des fichiers
filename="nextcloud_$(date "+%Y%m%d%H%M%S").zip"
dbfilename="nextcloud-db_$(date "+%Y%m%d%H%M%S").bak"

# Copie de la base de données dans un fichier
mysqldump --single-transaction -h 10.105.1.12 -u nextcloud -p'oui' nextcloud > /srv/backup/${dbfilename}   

# Copie des dossiers de nextcloud
cp -r /var/www/tp6_nextcloud/config/ /var/www/tp6_nextcloud/data/ /var/www/tp6_nextcloud/themes/ /srv/backup/

# Compression des dossiers et fichiers
zip -q -r /srv/backup/${filename} /srv/backup/config/ /srv/backup/data/ /srv/backup/themes/ /srv/backup/${dbfilename}

# Suppressions des copies après compression
rm -rf /srv/backup/${dbfilename} /srv/backup/config/ /srv/backup/data/ /srv/backup/themes/
