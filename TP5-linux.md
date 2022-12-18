# TP5 : Self-hosted cloud

# Partie 1 : Mise en place et maîtrise du serveur Web

## 1. Installation

🖥️ **VM web.tp5.linux**

🌞 **Installer le serveur Apache**

```
[hugoa@weblinuxtp5 ~]$ sudo dnf install httpd
```

🌞 **Démarrer le service Apache**

- le service s'appelle `httpd` (raccourci pour `httpd.service` en réalité)
  - démarrez-le

```
[hugoa@weblinuxtp5 ~]$ sudo systemctl start httpd
[hugoa@weblinuxtp5 ~]$ sudo systemctl status httpd | grep Active
     Active: active (running) since Mon 2022-12-12 16:12:40 CET; 4min 3s ago
```

  - faites en sorte qu'Apache démarre automatiquement au démarrage de la machine

```
[hugoa@weblinuxtp5 ~]$ sudo systemctl enable httpd
Created symlink /etc/systemd/system/multi-user.target.wants/httpd.service → /usr/lib/systemd/system/httpd.service.
```

  - ouvrez le port firewall nécessaire

```
[hugoa@weblinuxtp5 ~]$ sudo ss -alnpt | grep httpd
LISTEN 0      511                *:80              *:*    users:(("httpd",pid=4427,fd=4),("httpd",pid=4426,fd=4),("httpd",pid=4425,fd=4),("httpd",pid=4423,fd=4))

[hugoa@weblinuxtp5 ~]$ sudo firewall-cmd --add-port=80/tcp --permanent
success
[hugoa@weblinuxtp5 ~]$ sudo firewall-cmd --reload
success
[hugoa@weblinuxtp5 ~]$ sudo firewall-cmd --list-all | grep 80
  ports: 80/tcp
```

🌞 **TEST**

- vérifier que le service est démarré

```
[hugoa@weblinuxtp5 ~]$ sudo systemctl status httpd | grep Active
     Active: active (running) since Mon 2022-12-12 16:12:40 CET; 13min ago
```

- vérifier qu'il est configuré pour démarrer automatiquement

```
[hugoa@weblinuxtp5 ~]$ sudo systemctl status httpd | grep Loaded
     Loaded: loaded (/usr/lib/systemd/system/httpd.service; enabled; vendor preset: disabled)
```

- vérifier avec une commande `curl localhost` que vous joignez votre serveur web localement

```
[hugoa@weblinuxtp5 ~]$ curl --silent localhost | head -10
<!doctype html>
<html>
  <head>
    <meta charset='utf-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1'>
    <title>HTTP Server Test Page powered by: Rocky Linux</title>
    <style type="text/css">
      /*<![CDATA[*/
      
      html {
```

- vérifier depuis votre PC que vous accéder à la page par défaut

```
[hugoa@fedora ~]$ curl --silent 10.105.1.11:80 | head -10
<!doctype html>
<html>
  <head>
    <meta charset='utf-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1'>
    <title>HTTP Server Test Page powered by: Rocky Linux</title>
    <style type="text/css">
      /*<![CDATA[*/
      
      html {
```

## 2. Avancer vers la maîtrise du service

🌞 **Le service Apache...**

- affichez le contenu du fichier `httpd.service` qui contient la définition du service Apache

```
[hugoa@weblinuxtp5 ~]$ cat /usr/lib/systemd/system/httpd.service
# See httpd.service(8) for more information on using the httpd service.

# Modifying this file in-place is not recommended, because changes
# will be overwritten during package upgrades.  To customize the
# behaviour, run "systemctl edit httpd" to create an override unit.

# For example, to pass additional options (such as -D definitions) to
# the httpd binary at startup, create an override unit (as is done by
# systemctl edit) and enter the following:

#	[Service]
#	Environment=OPTIONS=-DMY_DEFINE

[Unit]
Description=The Apache HTTP Server
Wants=httpd-init.service
After=network.target remote-fs.target nss-lookup.target httpd-init.service
Documentation=man:httpd.service(8)

[Service]
Type=notify
Environment=LANG=C

ExecStart=/usr/sbin/httpd $OPTIONS -DFOREGROUND
ExecReload=/usr/sbin/httpd $OPTIONS -k graceful
# Send SIGWINCH for graceful stop
KillSignal=SIGWINCH
KillMode=mixed
PrivateTmp=true
OOMPolicy=continue

[Install]
WantedBy=multi-user.target
```

🌞 **Déterminer sous quel utilisateur tourne le processus Apache**

- mettez en évidence la ligne dans le fichier de conf principal d'Apache (`httpd.conf`) qui définit quel user est utilisé

```
[hugoa@weblinuxtp5 ~]$ cat /etc/httpd/conf/httpd.conf | grep 'User '
User apache
```

- utilisez la commande `ps -ef` pour visualiser les processus en cours d'exécution et confirmer que apache tourne bien sous l'utilisateur mentionné dans le fichier de conf

```
[hugoa@weblinuxtp5 ~]$ ps -ef | grep apache
apache      4424    4423  0 16:12 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
apache      4425    4423  0 16:12 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
apache      4426    4423  0 16:12 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
apache      4427    4423  0 16:12 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
hugoa       4836    3549  0 16:41 pts/0    00:00:00 grep --color=auto apache
```

- la page d'accueil d'Apache se trouve dans `/usr/share/testpage/`
  - vérifiez avec un `ls -al` que tout son contenu est **accessible en lecture** à l'utilisateur mentionné dans le fichier de conf

```
[hugoa@weblinuxtp5 ~]$ ls -al /usr/share/testpage/index.html
-rw-r--r--.  1 root root 7620 Jul 27 20:05 index.html
```

🌞 **Changer l'utilisateur utilisé par Apache**

- créez un nouvel utilisateur
 
```
[hugoa@weblinuxtp5 ~]$ sudo useradd apacheman -d /usr/share/httpd -s /sbin/nologin
useradd: warning: the home directory /usr/share/httpd already exists.
useradd: Not copying any file from skel directory into it.
[hugoa@weblinuxtp5 ~]$ cat /etc/passwd | grep apacheman
apacheman:x:1001:1001::/usr/share/httpd:/sbin/nologin
```

- modifiez la configuration d'Apache pour qu'il utilise ce nouvel utilisateur

```
[hugoa@weblinuxtp5 ~]$ cat /etc/httpd/conf/httpd.conf | grep 'User '
User apacheman
```

- redémarrez Apache

```
[hugoa@weblinuxtp5 ~]$ sudo systemctl restart httpd
```

- utilisez une commande `ps` pour vérifier que le changement a pris effet

```
[hugoa@weblinuxtp5 ~]$ ps -ef | grep httpd
root        4899       1  0 16:59 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
apachem+    4900    4899  0 16:59 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
apachem+    4901    4899  0 16:59 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
apachem+    4902    4899  0 16:59 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
apachem+    4903    4899  0 16:59 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
hugoa       5137    3549  0 17:02 pts/0    00:00:00 grep --color=auto httpd
```

🌞 **Faites en sorte que Apache tourne sur un autre port**

- modifiez la configuration d'Apache pour lui demander d'écouter sur un autre port de votre choix

```
[hugoa@weblinuxtp5 ~]$ echo $RANDOM
20149
[hugoa@weblinuxtp5 ~]$ sudo cat /etc/httpd/conf/httpd.conf | grep Listen
Listen 20149
```

- ouvrez ce nouveau port dans le firewall, et fermez l'ancien

```
[hugoa@weblinuxtp5 ~]$ sudo firewall-cmd --add-port=20149/tcp --permanent
success
[hugoa@weblinuxtp5 ~]$ sudo firewall-cmd --remove-port=80/tcp --permanent
success
[hugoa@weblinuxtp5 ~]$ sudo firewall-cmd --reload
success
[hugoa@weblinuxtp5 ~]$ sudo firewall-cmd --list-all | grep 20149
  ports: 20149/tcp
```

- prouvez avec une commande `ss` que Apache tourne bien sur le nouveau port choisi

```
[hugoa@weblinuxtp5 ~]$ sudo ss -alntp | grep httpd
[sudo] password for hugoa: 
LISTEN 0      511                *:20149            *:*    users:(("httpd",pid=5217,fd=4),("httpd",pid=5216,fd=4),("httpd",pid=5215,fd=4),("httpd",pid=5213,fd=4))
```

- vérifiez avec `curl` en local que vous pouvez joindre Apache sur le nouveau port

```
[hugoa@weblinuxtp5 ~]$ curl --silent localhost:20149 | head -10
<!doctype html>
<html>
  <head>
    <meta charset='utf-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1'>
    <title>HTTP Server Test Page powered by: Rocky Linux</title>
    <style type="text/css">
      /*<![CDATA[*/
      
      html {
```

- vérifiez avec votre navigateur que vous pouvez joindre le serveur sur le nouveau port

```
[hugoa@fedora ~]$ curl --silent 10.105.1.11:20149 | head -10
<!doctype html>
<html>
  <head>
    <meta charset='utf-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1'>
    <title>HTTP Server Test Page powered by: Rocky Linux</title>
    <style type="text/css">
      /*<![CDATA[*/
      
      html {
```

📁 **Fichier `/etc/httpd/conf/httpd.conf`**

**[httpd.conf](scripts/httpd.conf)**

# Partie 2 : Mise en place et maîtrise du serveur de base de données

🖥️ **VM db.tp5.linux**

🌞 **Install de MariaDB sur `db.tp5.linux`**

```
[hugoa@dbtp5linux ~]$ sudo dnf install mariadb-server

[hugoa@dbtp5linux ~]$ sudo systemctl enable mariadb
Created symlink /etc/systemd/system/mysql.service → /usr/lib/systemd/system/mariadb.service.
Created symlink /etc/systemd/system/mysqld.service → /usr/lib/systemd/system/mariadb.service.
Created symlink /etc/systemd/system/multi-user.target.wants/mariadb.service → /usr/lib/systemd/system/mariadb.service.

[hugoa@dbtp5linux ~]$ sudo systemctl start mariadb

[hugoa@dbtp5linux ~]$ sudo mysql_secure_installation
```

🌞 **Port utilisé par MariaDB**

- vous repérerez le port utilisé par MariaDB avec une commande `ss` exécutée sur `db.tp5.linux`

```
[hugoa@dbtp5linux ~]$ sudo ss -alntp | grep maria
[sudo] password for hugoa: 
LISTEN 0      80                 *:3306            *:*    users:(("mariadbd",pid=789,fd=19))
```

- il sera nécessaire de l'ouvrir dans le firewall

```
[hugoa@dbtp5linux ~]$ sudo firewall-cmd --add-port=3306/tcp --permanent
success
[hugoa@dbtp5linux ~]$ sudo firewall-cmd --reload
success
[hugoa@dbtp5linux ~]$ sudo firewall-cmd --list-all | grep 3306
  ports: 3306/tcp
```

🌞 **Processus liés à MariaDB**

- repérez les processus lancés lorsque vous lancez le service MariaDB

```
[hugoa@dbtp5linux ~]$ ps -ef | grep maria
mysql        789       1  0 10:47 ?        00:00:00 /usr/libexec/mariadbd --basedir=/usr
```

# Partie 3 : Configuration et mise en place de NextCloud


## 1. Base de données

🌞 **Préparation de la base pour NextCloud**

- une fois en place, il va falloir préparer une base de données pour NextCloud :
  - connectez-vous à la base de données à l'aide de la commande `sudo mysql -u root -p`
  - exécutez les commandes SQL suivantes :

```
MariaDB [(none)]> CREATE USER 'nextcloud'@'10.105.1.11' IDENTIFIED BY 'oui';
Query OK, 0 rows affected (0.020 sec)

MariaDB [(none)]> CREATE DATABASE IF NOT EXISTS nextcloud CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
Query OK, 1 row affected (0.001 sec)

MariaDB [(none)]> GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud'@'10.105.1.11';
Query OK, 0 rows affected (0.008 sec)

MariaDB [(none)]> FLUSH PRIVILEGES;
Query OK, 0 rows affected (0.001 sec)
```

🌞 **Exploration de la base de données**

- **donc vous devez effectuer une commande `mysql` sur `web.tp5.linux`**

```
[hugoa@weblinuxtp5 ~]$ mysql -u nextcloud -h 10.105.1.12 -p
Enter password: 
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 14
Server version: 5.5.5-10.5.16-MariaDB MariaDB Server

Copyright (c) 2000, 2022, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> SHOW DATABASES;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| nextcloud          |
+--------------------+
2 rows in set (0.00 sec)

mysql> USE nextcloud;
Database changed
mysql> SHOW TABLES;
Empty set (0.00 sec)

```

🌞 **Trouver une commande SQL qui permet de lister tous les utilisateurs de la base de données**

```
[hugoa@dbtp5linux ~]$ sudo mysql -u root -p

MariaDB [(none)]> SELECT user FROM mysql.user;
+-------------+
| User        |
+-------------+
| nextcloud   |
| mariadb.sys |
| mysql       |
| root        |
+-------------+
4 rows in set (0.002 sec)

```

## 2. Serveur Web et NextCloud

⚠️⚠️⚠️ **N'OUBLIEZ PAS de réinitialiser votre conf Apache avant de continuer. En particulier, remettez le port et le user par défaut.**

🌞 **Install de PHP**

```
[hugoa@weblinuxtp5 ~]$ sudo dnf config-manager --set-enabled crb

[hugoa@weblinuxtp5 ~]$ sudo dnf install dnf-utils http://rpms.remirepo.net/enterprise/remi-release-9.rpm -y

[hugoa@weblinuxtp5 ~]$ dnf module list php

[hugoa@weblinuxtp5 ~]$ sudo dnf module enable php:remi-8.1 -y

[hugoa@weblinuxtp5 ~]$ sudo dnf install -y php81-php
```

🌞 **Install de tous les modules PHP nécessaires pour NextCloud**

```bash
[hugoa@weblinuxtp5 ~]$ sudo dnf install -y libxml2 openssl php81-php php81-php-ctype php81-php-curl php81-php-gd php81-php-iconv php81-php-json php81-php-libxml php81-php-mbstring php81-php-openssl php81-php-posix php81-php-session php81-php-xml php81-php-zip php81-php-zlib php81-php-pdo php81-php-mysqlnd php81-php-intl php81-php-bcmath php81-php-gmp
```

🌞 **Récupérer NextCloud**

- créez le dossier `/var/www/tp5_nextcloud/`

```
[hugoa@weblinuxtp5 ~]$ sudo mkdir /var/www/tp5_nextcloud/
```

- récupérer le fichier suivant avec une commande `curl` ou `wget` : https://download.nextcloud.com/server/prereleases/nextcloud-25.0.0rc3.zip

```
[hugoa@weblinuxtp5 ~]$ curl https://download.nextcloud.com/server/prereleases/nextcloud-25.0.0rc3.zip -O
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  168M  100  168M    0     0  6636k      0  0:00:25  0:00:25 --:--:-- 6999k

[hugoa@weblinuxtp5 ~]$ ls
nextcloud-25.0.0rc3.zip
```

- extrayez tout son contenu dans le dossier `/var/www/tp5_nextcloud/` en utilisant la commande `unzip`

```
[hugoa@weblinuxtp5 ~]$ sudo dnf install unzip

[hugoa@weblinuxtp5 ~]$ unzip nextcloud-25.0.0rc3.zip
```

  - contrôlez que le fichier `/var/www/tp5_nextcloud/index.html` existe pour vérifier que tout est en place

```
[hugoa@weblinuxtp5 ~]$ mv nextcloud/* /var/www/tp5_nextcloud/

[hugoa@weblinuxtp5 tp5_nextcloud]$ ls -al | grep index.html 
-rw-r--r--.  1 apache apache   156 Oct  6 14:42 index.html
```

- **assurez-vous que le dossier `/var/www/tp5_nextcloud/` et tout son contenu appartient à l'utilisateur qui exécute le service Apache**

```
[hugoa@weblinuxtp5 tp5_nextcloud]$ sudo chown -R apache:apache .
[hugoa@weblinuxtp5 tp5_nextcloud]$ ls -al
total 140
drwxr-xr-x. 14 apache apache  4096 Dec 13 15:25 .
drwxr-xr-x.  5 root   root      54 Dec 13 14:40 ..
drwxr-xr-x. 47 apache apache  4096 Oct  6 14:47 3rdparty
drwxr-xr-x. 50 apache apache  4096 Oct  6 14:44 apps
-rw-r--r--.  1 apache apache 19327 Oct  6 14:42 AUTHORS
drwxr-xr-x.  2 apache apache    67 Oct  6 14:47 config
-rw-r--r--.  1 apache apache  4095 Oct  6 14:42 console.php
-rw-r--r--.  1 apache apache 34520 Oct  6 14:42 COPYING
drwxr-xr-x. 23 apache apache  4096 Oct  6 14:47 core
-rw-r--r--.  1 apache apache  6317 Oct  6 14:42 cron.php
drwxr-xr-x.  2 apache apache  8192 Oct  6 14:42 dist
-rw-r--r--.  1 apache apache  3253 Oct  6 14:42 .htaccess
-rw-r--r--.  1 apache apache   156 Oct  6 14:42 index.html
-rw-r--r--.  1 apache apache  3456 Oct  6 14:42 index.php
drwxr-xr-x.  6 apache apache   125 Oct  6 14:42 lib
-rw-r--r--.  1 apache apache   283 Oct  6 14:42 occ
drwxr-xr-x.  2 apache apache    23 Oct  6 14:42 ocm-provider
drwxr-xr-x.  2 apache apache    55 Oct  6 14:42 ocs
drwxr-xr-x.  2 apache apache    23 Oct  6 14:42 ocs-provider
-rw-r--r--.  1 apache apache  3139 Oct  6 14:42 public.php
-rw-r--r--.  1 apache apache  5426 Oct  6 14:42 remote.php
drwxr-xr-x.  4 apache apache   133 Oct  6 14:42 resources
-rw-r--r--.  1 apache apache    26 Oct  6 14:42 robots.txt
-rw-r--r--.  1 apache apache  2452 Oct  6 14:42 status.php
drwxr-xr-x.  3 apache apache    35 Oct  6 14:42 themes
drwxr-xr-x.  2 apache apache    43 Oct  6 14:44 updater
-rw-r--r--.  1 apache apache   101 Oct  6 14:42 .user.ini
-rw-r--r--.  1 apache apache   387 Oct  6 14:47 version.php
```

🌞 **Adapter la configuration d'Apache**

```
[hugoa@weblinuxtp5 ~]$ sudo vim /etc/httpd/conf.d/tp5_nextcloud.conf
[hugoa@weblinuxtp5 ~]$ sudo cat /etc/httpd/conf.d/tp5_nextcloud.conf
<VirtualHost *:80>
  # on indique le chemin de notre webroot
  DocumentRoot /var/www/tp5_nextcloud/
  # on précise le nom que saisissent les clients pour accéder au service
  ServerName  web.tp5.linux

  # on définit des règles d'accès sur notre webroot
  <Directory /var/www/tp5_nextcloud/> 
    Require all granted
    AllowOverride All
    Options FollowSymLinks MultiViews
    <IfModule mod_dav.c>
      Dav off
    </IfModule>
  </Directory>
</VirtualHost>
```

🌞 **Redémarrer le service Apache** pour qu'il prenne en compte le nouveau fichier de conf

```
[hugoa@weblinuxtp5 ~]$ sudo systemctl restart httpd
```

## 3. Finaliser l'installation de NextCloud

🌞 **Exploration de la base de données**

```
[hugoa@weblinuxtp5 ~]$ mysql -u nextcloud -h 10.105.1.12 -p

mysql> SELECT COUNT(*) AS nb_tables FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE';
+-----------+
| nb_tables |
+-----------+
|        95 |
+-----------+
1 row in set (0.01 sec)
```