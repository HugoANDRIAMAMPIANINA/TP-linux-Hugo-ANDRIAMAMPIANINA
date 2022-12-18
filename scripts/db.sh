#!/bin/bash

sed -i 's/enforcing/permissive/g' /etc/selinux/config
setenforce 0
echo 'db.tp5.linux' | tee /etc/hostname

dnf install mariadb-server -y > /dev/null
echo "mariadb-server installé avec succès"
systemctl enable mariadb
systemctl start mariadb

# Config de mysql_secure_installation
mysql -e "UPDATE mysql.global_priv SET priv=json_set(priv, '$.plugin', 'mysql_native_password', '$.authentication_string', PASSWORD('$esc_pass')) WHERE User='root';"
mysql -e "DELETE FROM mysql.global_priv WHERE User='';"
mysql -e "DELETE FROM mysql.global_priv WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
mysql -e "DROP DATABASE IF EXISTS test;"
mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%'"
mysql -e "FLUSH PRIVILEGES;"
mysql -e "UPDATE mysql.global_priv SET priv=json_set(priv, '$.password_last_changed', UNIX_TIMESTAMP(), '$.plugin', 'mysql_native_password', '$.authentication_string', 'invalid', '$.auth_or', json_array(json_object(), json_object('plugin', 'unix_socket'))) WHERE User='root';"


firewall-cmd --add-port=3306/tcp --permanent > /dev/null
firewall-cmd --reload > /dev/null
echo "Port ouvert avec succès"

systemctl restart mariadb

# Création user et base de données pour NextCloud
mysql -e "CREATE USER 'nextcloud'@'10.105.1.11' IDENTIFIED BY 'oui';"
mysql -e "CREATE DATABASE IF NOT EXISTS nextcloud CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
mysql -e "GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud'@'10.105.1.11';"
mysql -e "FLUSH PRIVILEGES;"

echo "Installation et config de mariadb et création d'un user et d'une base de données réussies"
