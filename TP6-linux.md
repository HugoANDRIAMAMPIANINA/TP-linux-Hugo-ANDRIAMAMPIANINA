# TP6 : Travail autour de la solution NextCloud

# Module 1 : Reverse Proxy

# I. Setup

🖥️ **VM `proxy.tp6.linux`**

🌞 **On utilisera NGINX comme reverse proxy**

- installer le paquet `nginx`

```
[hugoa@proxytp6linux ~]$ sudo dnf install nginx
```

- démarrer le service `nginx`

```
[hugoa@proxytp6linux ~]$ sudo systemctl start nginx
```

- utiliser la commande `ss` pour repérer le port sur lequel NGINX écoute

```
[hugoa@proxytp6linux ~]$ sudo ss -alntp | grep nginx
LISTEN 0      511          0.0.0.0:80        0.0.0.0:*    users:(("nginx",pid=1410,fd=6),("nginx",pid=1409,fd=6))
LISTEN 0      511             [::]:80           [::]:*    users:(("nginx",pid=1410,fd=7),("nginx",pid=1409,fd=7))
```

- ouvrir un port dans le firewall pour autoriser le trafic vers NGINX

```
[hugoa@proxytp6linux ~]$ sudo firewall-cmd --add-port=80/tcp --permanent
success
[hugoa@proxytp6linux ~]$ sudo firewall-cmd --reload
success
[hugoa@proxytp6linux ~]$ sudo firewall-cmd --list-all | grep 80
  ports: 80/tcp
```

- utiliser une commande `ps -ef` pour déterminer sous quel utilisateur tourne NGINX

```
[hugoa@proxytp6linux ~]$ ps -ef | grep 1410
nginx       1410    1409  0 15:39 ?        00:00:00 nginx: worker process
```

- vérifier que le page d'accueil NGINX est disponible en faisant une requête HTTP sur le port 80 de la machine

```
[hugoa@proxytp6linux ~]$ curl 10.105.1.13:80 | head -5
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0<!doctype html>
<html>
  <head>
    <meta charset='utf-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1'>
```

🌞 **Configurer NGINX**

- Deux choses à faire :
  - créer un fichier de configuration NGINX
    ```
    [hugoa@proxytp6linux ~]$ sudo cat /etc/nginx/conf.d/reverse_proxy.conf
    server {
        # On indique le nom que client va saisir pour accéder au service
        # Pas d'erreur ici, c'est bien le nom de web, et pas de proxy qu'on veut ici !
        server_name web.tp6.linux;

        # Port d'écoute de NGINX
        listen 80;

        location / {
            # On définit des headers HTTP pour que le proxying se passe bien
            proxy_set_header  Host $host;
            proxy_set_header  X-Real-IP $remote_addr;
            proxy_set_header  X-Forwarded-Proto https;
            proxy_set_header  X-Forwarded-Host $remote_addr;
            proxy_set_header  X-Forwarded-For $proxy_add_x_forwarded_for;

            # On définit la cible du proxying 
            proxy_pass http://<IP_DE_NEXTCLOUD>:80;
        }

        # Deux sections location recommandés par la doc NextCloud
        location /.well-known/carddav {
        return 301 $scheme://$host/remote.php/dav;
        }

        location /.well-known/caldav {
        return 301 $scheme://$host/remote.php/dav;
        }
    }
    ```

  - NextCloud est un peu exigeant, et il demande à être informé si on le met derrière un reverse proxy
    - y'a donc un fichier de conf NextCloud à modifier
    - c'est un fichier appelé `config.php`

    ```
    [hugoa@webtp6linux ~]$ sudo cat /var/www/tp6_nextcloud/config/config.php
    <?php
    $CONFIG = array (
    'instanceid' => 'ocfzt8jb6s6o',
    'passwordsalt' => 'TATEHXW+so91jMH0xe+S2Ix+MKGl1f',
    'secret' => 'gHZy1GZ/TFv9yLWkMrrE/TKwkwwXsJ6VnPen28frfCJzQ9DK',
    'trusted_domains' =>
    array (
        0 => 'web.tp6.linux',
    ),
    'overwriteprotocol' => 'http',
    'datadirectory' => '/var/www/tp6_nextcloud/data',
    'dbtype' => 'mysql',
    'version' => '25.0.0.15',
    'overwrite.cli.url' => 'http://web.tp6.linux',
    'dbname' => 'nextcloud',
    'dbhost' => '10.105.1.12',
    'dbport' => '',
    'dbtableprefix' => 'oc_',
    'mysql.utf8mb4' => true,
    'dbuser' => 'nextcloud',
    'dbpassword' => 'oui',
    'installed' => true,
    );
    ```

➜ **Modifier votre fichier `hosts` de VOTRE PC**

```
[hugoa@fedora ~]$ sudo cat /etc/hosts | grep web
10.105.1.13 web.tp6.linux

[hugoa@webtp6linux ~]$ curl http://web.tp6.linux/index.php/login
<!DOCTYPE html>
<html class="ng-csp" data-placeholder-focus="false" lang="en" data-locale="en" >
	<head
 data-requesttoken="m8fr+1WDMp8/KZtdZkkBw6BFkx3nymQmuQ5kVi7STEA=:+OihgWTpatV5QNE6FX5wp9QQ+2+WjzFcj34lYUKTeXI=">
		<meta charset="utf-8">
		<title>
			Login – Nextcloud		</title>
		<meta name="viewport" content="width=device-width, initial-scale=1.0, minimum-scale=1.0">
				<meta name="apple-itunes-app" content="app-id=1125420102">
```

🌞 **Faites en sorte de**

- rendre le serveur `web.tp6.linux` injoignable
- sauf depuis l'IP du reverse proxy

```
[hugoa@webtp6linux ~]$ sudo firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="10.105.1.13/32" invert="True" drop' --permanent
success
[hugoa@webtp6linux ~]$ sudo firewall-cmd --reload
success
[hugoa@webtp6linux ~]$ sudo firewall-cmd --list-all | grep 'rule family'
	rule family="ipv4" source NOT address="10.105.1.13/32" drop
```

🌞 **Une fois que c'est en place**

- faire un `ping` manuel vers l'IP de `proxy.tp6.linux` fonctionne

```
[hugoa@fedora ~]$ ping 10.105.1.13
PING 10.105.1.13 (10.105.1.13) 56(84) bytes of data.
64 bytes from 10.105.1.13: icmp_seq=1 ttl=64 time=0.551 ms
64 bytes from 10.105.1.13: icmp_seq=2 ttl=64 time=0.847 ms
^C
--- 10.105.1.13 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1051ms
rtt min/avg/max/mdev = 0.551/0.699/0.847/0.148 ms
```

- faire un `ping` manuel vers l'IP de `web.tp6.linux` ne fonctionne pas

```
[hugoa@fedora ~]$ ping 10.105.1.11
PING 10.105.1.11 (10.105.1.11) 56(84) bytes of data.
^C
--- 10.105.1.11 ping statistics ---
3 packets transmitted, 0 received, 100% packet loss, time 2053ms
```

# II. HTTPS

Le but de cette section est de permettre une connexion chiffrée lorsqu'un client se connecte. Avoir le ptit HTTPS :)

Le principe :

- on génère une paire de clés sur le serveur `proxy.tp6.linux`
  
```
[hugoa@proxytp6linux ~]$ openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 -keyout server.key -out server.crt
[hugoa@proxytp6linux ~]$ ls
server.crt  server.key
```

- on ajuste la conf NGINX

```
[hugoa@proxytp6linux ~]$ sudo cat /etc/nginx/conf.d/reverse_proxy.conf
server {
    # On indique le nom que client va saisir pour accéder au service
    # Pas d'erreur ici, c'est bien le nom de web, et pas de proxy qu'on veut ici !
    server_name web.tp6.linux;

    # Port d'écoute de NGINX
    listen 443 ssl;
    ssl_certificate /home/hugoa/server.crt;
    ssl_certificate_key /home/hugoa/server.key;

    location / {
        # On définit des headers HTTP pour que le proxying se passe bien
        proxy_set_header  Host $host;
        proxy_set_header  X-Real-IP $remote_addr;
        proxy_set_header  X-Forwarded-Proto https;
        proxy_set_header  X-Forwarded-Host $remote_addr;
        proxy_set_header  X-Forwarded-For $proxy_add_x_forwarded_for;

        # On définit la cible du proxying 
        proxy_pass http://10.105.1.11:80;
    }

    # Deux sections location recommandés par la doc NextCloud
    location /.well-known/carddav {
      return 301 $scheme://$host/remote.php/dav;
    }

    location /.well-known/caldav {
      return 301 $scheme://$host/remote.php/dav;
    }
}
```

# Module 2 : Sauvegarde du système de fichiers

## I. Script de backup

Partie à réaliser sur `web.tp6.linux`

### 1. Ecriture du script

🌞 **Ecrire le script `bash`**

**[tp6_backup.sh](scripts/tp6_backup.sh)**

➜ **Environnement d'exécution du script**

- créez un utilisateur sur la machine `web.tp6.linux`

```
[hugoa@webtp6linux ~]$ sudo useradd backup -d /srv/backup/ -s /usr/bin/nologin
```

### 3. Service et timer

🌞 **Créez un *service*** système qui lance le script

```
[hugoa@webtp6linux ~]$ sudo cat /etc/systemd/system/backup.service
[Unit]
Description=Service de sauvegarde du système de fichiers

[Service]
ExecStart=/srv/tp6_backup.sh
User=backup
Type=oneshot

[Install]
WantedBy=multi-user.target
```
```
[hugoa@webtp6linux ~]$ sudo systemctl status backup
○ backup.service - Service de sauvegarde du système de fichiers
     Loaded: loaded (/etc/systemd/system/backup.service; disabled; vendor preset: disabled)
     Active: inactive (dead)

Jan 16 17:55:29 webtp6linux systemd[1]: backup.service: Deactivated successfully.
Jan 16 17:55:29 webtp6linux systemd[1]: Finished Service de sauvegarde du système de fichiers.
```

🌞 **Créez un *timer*** système qui lance le *service* à intervalles réguliers

```
[hugoa@webtp6linux ~]$ sudo cat /etc/systemd/system/backup.timer
[Unit]
Description=Run service backup

[Timer]
OnCalendar=*-*-* 4:00:00

[Install]
WantedBy=timers.target
```

🌞 Activez l'utilisation du *timer*

- vous vous servirez des commandes suivantes :

```bash
[hugoa@webtp6linux ~]$ sudo systemctl start backup.timer
[hugoa@webtp6linux ~]$ sudo systemctl enable backup.timer
Created symlink /etc/systemd/system/timers.target.wants/backup.timer → /etc/systemd/system/backup.timer.
[hugoa@webtp6linux ~]$ sudo systemctl status backup.timer
● backup.timer - Run service backup
     Loaded: loaded (/etc/systemd/system/backup.timer; enabled; vendor preset: disabled)
     Active: active (waiting) since Mon 2023-01-16 18:04:05 CET; 15s ago
      Until: Mon 2023-01-16 18:04:05 CET; 15s ago
    Trigger: Tue 2023-01-17 04:00:00 CET; 9h left
   Triggers: ● backup.service

Jan 16 18:04:05 webtp6linux systemd[1]: Started Run service backup.

[hugoa@webtp6linux ~]$ sudo systemctl list-timers | grep backup
Tue 2023-01-17 04:00:00 CET 9h left       n/a                         n/a          backup.timer                 backup.service
```

## II. NFS

### 1. Serveur NFS

🖥️ **VM `storage.tp6.linux`**

🌞 **Préparer un dossier à partager sur le réseau** (sur la machine `storage.tp6.linux`)

```
[hugoa@storagetp6linux ~]$ sudo mkdir -p /srv/nfs_shares/web.tp6.linux

[hugoa@storagetp6linux ~]$ sudo chown nobody /srv/nfs_shares/web.tp6.linux/
[hugoa@storagetp6linux ~]$ sudo chown nobody /srv/nfs_shares/
[hugoa@storagetp6linux ~]$ ls -al /srv
total 0
drwxr-xr-x.  3 root   root  24 Jan 16 18:23 .
dr-xr-xr-x. 18 root   root 235 Nov 26 18:23 ..
drwxr-xr-x.  3 nobody root  27 Jan 16 18:24 nfs_shares
```

🌞 **Installer le serveur NFS** (sur la machine `storage.tp6.linux`)

- installer le paquet `nfs-utils`

```
[hugoa@storagetp6linux ~]$ sudo dnf install nfs-utils
```

- créer le fichier `/etc/exports`

```
[hugoa@storagetp6linux ~]$ sudo cat /etc/exports
/srv/nfs_shares/web.tp6.linux 10.105.1.11(rw,sync,no_subtree_check)
```

- ouvrir les ports firewall nécessaires

```
[hugoa@storagetp6linux ~]$ sudo firewall-cmd --permanent --add-service=nfs
success
[hugoa@storagetp6linux ~]$ sudo firewall-cmd --permanent --add-service=mountd
success
[hugoa@storagetp6linux ~]$ sudo firewall-cmd --permanent --add-service=rpc-bind
success
[hugoa@storagetp6linux ~]$ sudo firewall-cmd --reload
success
[hugoa@storagetp6linux ~]$ sudo firewall-cmd --list-all | grep services
  services: cockpit dhcpv6-client mountd nfs rpc-bind ssh
```

- démarrer le service

```
[hugoa@storagetp6linux ~]$ sudo systemctl enable nfs-server
Created symlink /etc/systemd/system/multi-user.target.wants/nfs-server.service → /usr/lib/systemd/system/nfs-server.service.
[hugoa@storagetp6linux ~]$ sudo systemctl start nfs-server
[hugoa@storagetp6linux ~]$ sudo systemctl status nfs-server
● nfs-server.service - NFS server and services
     Loaded: loaded (/usr/lib/systemd/system/nfs-server.service; enabled; ven>
    Drop-In: /run/systemd/generator/nfs-server.service.d
             └─order-with-mounts.conf
     Active: active (exited) since Mon 2023-01-16 18:42:54 CET; 11s ago
    Process: 2083 ExecStartPre=/usr/sbin/exportfs -r (code=exited, status=1/F>
    Process: 2084 ExecStart=/usr/sbin/rpc.nfsd (code=exited, status=0/SUCCESS)
    Process: 2102 ExecStart=/bin/sh -c if systemctl -q is-active gssproxy; th>
   Main PID: 2102 (code=exited, status=0/SUCCESS)
        CPU: 27ms

Jan 16 18:42:53 storagetp6linux systemd[1]: Starting NFS server and services.>
Jan 16 18:42:53 storagetp6linux exportfs[2083]: exportfs: Failed to stat /srv>
Jan 16 18:42:54 storagetp6linux systemd[1]: Finished NFS server and services.
```

### 2. Client NFS

🌞 **Installer un client NFS sur `web.tp6.linux`**

```
[hugoa@webtp6linux ~]$ sudo mount 10.105.1.14:/srv/nfs_shares/web.tp6.linux /srv/backup

[hugoa@webtp6linux ~]$ df -h | grep 10.105.1.14
10.105.1.14:/srv/nfs_shares/web.tp6.linux  6.2G  1.3G  4.9G  21% /srv/backup

[hugoa@webtp6linux ~]$ sudo cat /etc/fstab | grep 10.105.1.14
10.105.1.14:/srv/nfs_shares/web.tp6.linux /srv/backup nfs defaults 0 0
```

🌞 **Tester la restauration des données** sinon ça sert à rien :)

- livrez-moi la suite de commande que vous utiliseriez pour restaurer les données dans une version antérieure

```bash

# décompresse le .zip
unzip /srv/backup/nextcloud_yyyywwddhhmmss.zip

# copie des dossiers de backup dans le dossier nextcloud
cp -a /srv/backup/config/. /var/www/tp6_nextcloud/config/
cp -a /srv/backup/data/. /var/www/tp6_nextcloud/data/
cp -a /srv/backup/themes/. /var/www/tp6_nextcloud/themes/

# suppression puis restauration de la base de données
mysql -h 10.105.1.12 -u nextcloud -p'oui' -e "DROP DATABASE nextcloud"
mysql -h 10.105.1.12 -u nextcloud -p'oui' -e "CREATE DATABASE nextcloud"
mysql -h 10.105.1.12 -u nextcloud -p'oui' nextcloud < nextcloud-db_yyyymmddhhmmss.bak
```

# Module 3 : Fail2Ban

🌞 Faites en sorte que :

- si quelqu'un se plante 3 fois de password pour une co SSH en moins de 1 minute, il est ban

```
[hugoa@dbtp6linux ~]$ sudo cat /etc/fail2ban/jail.local
[...]
findtime  = 1m
[...]
maxretry = 3
[...]
[sshd]
[...]
enabled = true
```

- vérifiez que ça fonctionne en vous faisant ban

```
[hugoa@webtp6linux ~]$ ssh francis@10.105.1.12
The authenticity of host '10.105.1.12 (10.105.1.12)' can't be established.
ED25519 key fingerprint is SHA256:wU2yjvfN58qGx8IxP4rcolXZP/6CNSh4LaKpbqBAs2I.
This key is not known by any other names
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '10.105.1.12' (ED25519) to the list of known hosts.
francis@10.105.1.12's password: 
Permission denied, please try again.
francis@10.105.1.12's password: 
Permission denied, please try again.
francis@10.105.1.12's password: 
francis@10.105.1.12: Permission denied (publickey,gssapi-keyex,gssapi-with-mic,password).

[hugoa@webtp6linux ~]$ ssh francis@10.105.1.12
ssh: connect to host 10.105.1.12 port 22: Connection refused
```

- utilisez une commande dédiée pour lister les IPs qui sont actuellement ban

```
[hugoa@dbtp6linux ~]$ sudo fail2ban-client status sshd | grep Banned
   `- Banned IP list:	10.105.1.11
```

- afficher l'état du firewall, et trouver la ligne qui ban l'IP en question

- lever le ban avec une commande liée à fail2ban

```
[hugoa@dbtp6linux ~]$ sudo fail2ban-client set sshd unbanip 10.105.1.11
1
[hugoa@dbtp6linux ~]$ sudo fail2ban-client status sshd | grep Banned
   `- Banned IP list:	
```

# Module 4 : Monitoring

🌞 **Installer Netdata**

- installez-le sur `web.tp6.linux` et `db.tp6.linux`.

```bash
[hugoa@webtp6linux ~]$ sudo systemctl start netdata
[hugoa@webtp6linux ~]$ sudo systemctl enable netdata
[hugoa@webtp6linux ~]$ sudo systemctl status netdata | head -3 
● netdata.service - Real time performance monitoring
     Loaded: loaded (/usr/lib/systemd/system/netdata.service; enabled; vendor preset: disabled)
     Active: active (running) since Mon 2023-01-16 22:08:57 CET; 12min ago


[hugoa@dbtp6linux ~]$ sudo systemctl start netdata
[hugoa@dbtp6linux ~]$ sudo systemctl enable netdata
[hugoa@dbtp6linux ~]$ sudo systemctl status netdata | head -3
● netdata.service - Real time performance monitoring
     Loaded: loaded (/usr/lib/systemd/system/netdata.service; enabled; vendor preset: disabled)
     Active: active (running) since Mon 2023-01-16 22:14:43 CET; 4min 6s ago
```

➜ **Une fois en place**, Netdata déploie une interface un Web pour avoir moult stats en temps réel, utilisez une commande `ss` pour repérer sur quel port il tourne.

```bash
# port : 19999

[hugoa@webtp6linux ~]$ sudo ss -alnpt | grep netdata
LISTEN 0      4096         0.0.0.0:19999      0.0.0.0:*    users:(("netdata",pid=26476,fd=6)) 
LISTEN 0      4096       127.0.0.1:8125       0.0.0.0:*    users:(("netdata",pid=26476,fd=41))
LISTEN 0      4096            [::]:19999         [::]:*    users:(("netdata",pid=26476,fd=7)) 
LISTEN 0      4096           [::1]:8125          [::]:*    users:(("netdata",pid=26476,fd=40))
```

🌞 **Une fois Netdata installé et fonctionnel, déterminer :**

- l'utilisateur sous lequel tourne le(s) processus Netdata

```bash
# user : netdata

[hugoa@webtp6linux ~]$ ps -ef | grep 26476
netdata    26476       1  1 22:14 ?        00:00:11 /opt/netdata/bin/srv/netdata -P /run/netdata/netdata.pid -D
netdata    26479   26476  0 22:14 ?        00:00:00 /opt/netdata/bin/srv/netdata --special-spawn-server
root       26643   26476  0 22:14 ?        00:00:01 /opt/netdata/usr/libexec/netdata/plugins.d/ebpf.plugin 1
root       26646   26476  1 22:14 ?        00:00:09 /opt/netdata/usr/libexec/netdata/plugins.d/apps.plugin 1
netdata    26650   26476  0 22:14 ?        00:00:02 /opt/netdata/usr/libexec/netdata/plugins.d/go.d.plugin 1
netdata    26660   26476  0 22:14 ?        00:00:01 bash /opt/netdata/usr/libexec/netdata/plugins.d/tc-qos-helper.sh 1
```

- si Netdata écoute sur des ports

```
[hugoa@webtp6linux ~]$ sudo cat /etc/netdata/netdata.conf | grep ' port '
	# default port = 19999
	# default port = 8125
```

- comment sont consultables les logs de Netdata

```
[hugoa@webtp6linux ~]$ sudo cat /var/log/netdata/access.log
```

🌞 **Configurer Netdata pour qu'il vous envoie des alertes** 

```
[hugoa@webtp6linux ~]$ sudo cat /etc/netdata/health_alarm_notify.conf
###############################################################################
# sending discord notifications

# note: multiple recipients can be given like this:
#                  "CHANNEL1 CHANNEL2 ..."

# enable/disable sending discord notifications
SEND_DISCORD="YES"

# Create a webhook by following the official documentation -
# https://support.discordapp.com/hc/en-us/articles/228383668-Intro-to-Webhooks
DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/1064668205202808872/pOgbQh7hXFdsGunZgoKyh4w1zdDYKKH1Ng6VOAAk7NNGcaiRPInXBVGTUCduVbytYKFS"

# if a role's recipients are not configured, a notification will be send to
# this discord channel (empty = do not send a notification for unconfigured
# roles):
DEFAULT_RECIPIENT_DISCORD="alarms"
```

🌞 **Vérifier que les alertes fonctionnent**

```
[hugoa@webtp6linux ~]$ sudo stress -c 8 -t 20s
stress: info: [48088] dispatching hogs: 8 cpu, 0 io, 0 vm, 0 hdd
stress: info: [48088] successful run completed in 20s
```