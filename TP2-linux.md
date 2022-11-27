# TP2 : Appréhender l'environnement Linux

# I. Service SSH

Le service SSH est déjà installé sur la machine, et il est aussi déjà démarré par défaut, c'est Rocky qui fait ça nativement.

## 1. Analyse du service

On va, dans cette première partie, analyser le service SSH qui est en cours d'exécution.

🌞 **S'assurer que le service `sshd` est démarré**

```
[hugoa@tp2linux ~]$ systemctl status sshd | grep active
     Active: active (running) since Tue 2022-11-22 16:23:53 CET; 8min ago
```

🌞 **Analyser les processus liés au service SSH**

```
[hugoa@tp2linux ~]$ ps -ef | grep sshd
root         688       1  0 16:23 ?        00:00:00 sshd: /usr/sbin/sshd -D [listener] 0 of 10-100 startups
root         857     688  0 16:24 ?        00:00:00 sshd: hugoa [priv]
hugoa        861     857  0 16:25 ?        00:00:00 sshd: hugoa@pts/0
hugoa        940     862  0 16:39 pts/0    00:00:00 grep --color=auto sshd
```

🌞 **Déterminer le port sur lequel écoute le service SSH**

```
[hugoa@tp2linux ~]$ ss | grep ssh
tcp   ESTAB  0      52                        10.2.2.2:ssh           10.2.2.1:58205
```

🌞 **Consulter les logs du service SSH**

```
[hugoa@tp2linux ~]$ sudo cat /var/log/secure | grep sshd | tail -n 10
Nov 22 16:10:25 localhost sshd[1066]: Accepted password for hugoa from 10.2.2.1 port 51386 ssh2
Nov 22 16:10:25 localhost sshd[1066]: pam_unix(sshd:session): session opened for user hugoa(uid=1000) by (uid=0)
Nov 22 16:13:14 tp2linux sshd[689]: Server listening on 0.0.0.0 port 22.
Nov 22 16:13:14 tp2linux sshd[689]: Server listening on :: port 22.
Nov 22 16:13:28 tp2linux sshd[816]: Accepted password for hugoa from 10.2.2.1 port 62160 ssh2
Nov 22 16:13:28 tp2linux sshd[816]: pam_unix(sshd:session): session opened for user hugoa(uid=1000) by (uid=0)
Nov 22 16:23:53 tp2linux sshd[688]: Server listening on 0.0.0.0 port 22.
Nov 22 16:23:53 tp2linux sshd[688]: Server listening on :: port 22.
Nov 22 16:25:01 tp2linux sshd[857]: Accepted password for hugoa from 10.2.2.1 port 58205 ssh2
Nov 22 16:25:01 tp2linux sshd[857]: pam_unix(sshd:session): session opened for user hugoa(uid=1000) by (uid=0)
```

## 2. Modification du service

Dans cette section, on va aller visiter et modifier le fichier de configuration du serveur SSH.

Comme tout fichier de configuration, celui de SSH se trouve dans le dossier `/etc/`.

Plus précisément, il existe un sous-dossier `/etc/ssh/` qui contient toute la configuration relative au protocole SSH

🌞 **Identifier le fichier de configuration du serveur SSH**

```
[hugoa@tp2linux ssh]$ sudo cat sshd_config | grep Port
#Port 22
#GatewayPorts no
```

🌞 **Modifier le fichier de conf**

- exécutez un `echo $RANDOM` pour demander à votre shell de vous fournir un nombre aléatoire
  ```
  [hugoa@tp2linux ssh]$ echo $RANDOM
  3123
  ```
- changez le port d'écoute du serveur SSH pour qu'il écoute sur ce numéro de port
  ```
  [hugoa@tp2linux ~]$ sudo cat /etc/ssh/sshd_config | grep Port
  Port 3123
  #GatewayPorts no
  ```
- gérer le firewall
  ```bash
  # fermeture ancien port
  [hugoa@tp2linux ~]$ sudo firewall-cmd --remove-port=22/tcp --permanent
  success

  # ouverture nouveau port
  [hugoa@tp2linux ~]$ sudo firewall-cmd --add-port=3123/tcp --permanent
  success

  # modifs bien apportées
  [hugoa@tp2linux ~]$ sudo firewall-cmd --list-all | grep ports
  ports: 3123/tcp
  forward-ports:
  source-ports:
  ```

🌞 **Redémarrer le service**

```
[hugoa@tp2linux ~]$ systemctl status sshd
```

🌞 **Effectuer une connexion SSH sur le nouveau port**

```
PS C:\Users\hugoa> ssh -p 3123 hugoa@tp2linux
hugoa@tp2linux's password:
Last login: Tue Nov 22 22:21:46 2022 from 10.2.2.1
[hugoa@tp2linux ~]$
```

✨ **Bonus : affiner la conf du serveur SSH**

- faites vos plus belles recherches internet pour améliorer la conf de SSH
- par "améliorer" on entend essentiellement ici : augmenter son niveau de sécurité
- le but c'est pas de me rendre 10000 lignes de conf que vous pompez sur internet pour le bonus, mais de vous éveiller à divers aspects de SSH, la sécu ou d'autres choses liées


# II. Service HTTP

## 1. Mise en place

🌞 **Installer le serveur NGINX**

```
[hugoa@tp2linux ~]$ sudo dnf install nginx
```

🌞 **Démarrer le service NGINX**

```bash
[hugoa@tp2linux ~]$ sudo systemctl enable nginx
[hugoa@tp2linux ~]$ sudo systemctl start nginx
[hugoa@tp2linux ~]$ sudo systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; vendor preset: disabled)
     Active: active (running) since Tue 2022-11-22 22:56:21 CET; 4min 0s ago
    Process: 1363 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
    Process: 1364 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
    Process: 1365 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
   Main PID: 1366 (nginx)
      Tasks: 2 (limit: 5904)
     Memory: 1.9M
        CPU: 13ms
     CGroup: /system.slice/nginx.service
             ├─1366 "nginx: master process /usr/sbin/nginx"
             └─1367 "nginx: worker process"

Nov 22 22:56:21 tp2linux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Nov 22 22:56:21 tp2linux nginx[1364]: nginx: the configuration file /etc/nginx/nginx.conf sy>
Nov 22 22:56:21 tp2linux nginx[1364]: nginx: configuration file /etc/nginx/nginx.conf test i>
Nov 22 22:56:21 tp2linux systemd[1]: Started The nginx HTTP and reverse proxy server.
```

🌞 **Déterminer sur quel port tourne NGINX**

```bash
# détermination du port 
[hugoa@tp2linux ~]$ cat /etc/nginx/nginx.conf | grep listen
        listen       80;
        listen       [::]:80;
#        listen       443 ssl http2;
#        listen       [::]:443 ssl http2;

# ouverture port 80/tcp
[hugoa@tp2linux ~]$ sudo firewall-cmd --permanent --add-port=80/tcp
success
[hugoa@tp2linux ~]$ sudo firewall-cmd --reload
success
[hugoa@tp2linux ~]$ sudo firewall-cmd --list-all | grep port
  ports: 22/tcp 80/tcp
  forward-ports:
  source-ports:
```

🌞 **Déterminer les processus liés à l'exécution de NGINX**

```bash
[hugoa@tp2linux ~]$ ps -ef | grep -i NGINX
root        1366       1  0 22:56 ?        00:00:00 nginx: master process /usr/sbin/nginx
nginx       1367    1366  0 22:56 ?        00:00:00 nginx: worker process
murci       1560    1177  0 23:21 pts/0    00:00:00 grep --color=auto -i NGINX
```

🌞 **Euh wait**

```bash
hugoa@SeigneurHugoPCMasterRace MINGW64 ~
$ curl 10.2.2.2 | head -n 7
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  7620  100  7620    0     0  3242k      0 --:--:-- --:--:-- --:--:-- 3720k
<!doctype html>
<html>
  <head>
    <meta charset='utf-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1'>
    <title>HTTP Server Test Page powered by: Rocky Linux</title>
    <style type="text/css">

```

## 2. Analyser la conf de NGINX

🌞 **Déterminer le path du fichier de configuration de NGINX**

```
[hugoa@tp2linux ~]$ ls -al /etc/nginx/nginx.conf
-rw-r--r--. 1 root root 2334 May 16  2022 /etc/nginx/nginx.conf
```

🌞 **Trouver dans le fichier de conf**

```bash
# afficher lignes qui font tourner la page moche
[hugoa@tp2linux ~]$ cat /etc/nginx/nginx.conf | grep "server {" -A 16
    server {
        listen       80;
        listen       [::]:80;
        server_name  _;
        root         /usr/share/nginx/html;

        # Load configuration files for the default server block.
        include /etc/nginx/default.d/*.conf;

        error_page 404 /404.html;
        location = /404.html {
        }

        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
        }
    }
--
#    server {
#        listen       443 ssl http2;
#        listen       [::]:443 ssl http2;
#        server_name  _;
#        root         /usr/share/nginx/html;
#
#        ssl_certificate "/etc/pki/nginx/server.crt";
#        ssl_certificate_key "/etc/pki/nginx/private/server.key";
#        ssl_session_cache shared:SSL:1m;
#        ssl_session_timeout  10m;
#        ssl_ciphers PROFILE=SYSTEM;
#        ssl_prefer_server_ciphers on;
#
#        # Load configuration files for the default server block.
#        include /etc/nginx/default.d/*.conf;
#
#        error_page 404 /404.html;
```

```bash
# affiche ligne qui parle d'inclure d'autres fichiers de conf
[hugoa@tp2linux ~]$ cat /etc/nginx/nginx.conf | grep "conf.d"
    # Load modular configuration files from the /etc/nginx/conf.d directory.
    include /etc/nginx/conf.d/*.conf;
```

## 3. Déployer un nouveau site web

🌞 **Créer un site web**

```bash
[hugoa@tp2linux tp2_linux]$ cat index.html
<h1>MEOW mon premier serveur web</h1>
```

🌞 **Adapter la conf NGINX**

```bash
[hugoa@tp2linux /]$ cat /etc/nginx/nginx.conf | grep "server {" -A 16
#    server {
#        listen       443 ssl http2;
#        listen       [::]:443 ssl http2;
#        server_name  _;
#        root         /usr/share/nginx/html;
#
#        ssl_certificate "/etc/pki/nginx/server.crt";
#        ssl_certificate_key "/etc/pki/nginx/private/server.key";
#        ssl_session_cache shared:SSL:1m;
#        ssl_session_timeout  10m;
#        ssl_ciphers PROFILE=SYSTEM;
#        ssl_prefer_server_ciphers on;
#
#        # Load configuration files for the default server block.
#        include /etc/nginx/default.d/*.conf;
#
#        error_page 404 /404.html;

# redémarrage de NGINX
[hugoa@tp2linux /]$ sudo systemctl restart nginx
```
```bash
[hugoa@tp2linux /]$ echo $RANDOM
26706

[hugoa@tp2linux /]$ sudo cat /etc/nginx/conf.d/supersite.conf
server {
  # le port choisi devra être obtenu avec un 'echo $RANDOM' là encore
  listen 26706;

  root /var/www/tp2_linux;
}

[hugoa@tp2linux /]$ sudo firewall-cmd --add-port=26706/tcp --permanent
success
[hugoa@tp2linux /]$ sudo firewall-cmd --reload
success
[hugoa@tp2linux /]$ sudo firewall-cmd --list-all | grep ports
  ports: 22/tcp 80/tcp 26706/tcp
  forward-ports:
  source-ports:

[hugoa@tp2linux /]$ sudo systemctl restart nginx
```

🌞 **Visitez votre super site web**

```bash
hugoa@SeigneurHugoPCMasterRace MINGW64 ~
$ curl 10.2.2.2:26706
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100    38  100    38    0     0   3261      0 --:--:-- --:--:-- --:--:--  3454<h1>MEOW mon premier serveur web</h1>


```

# III. Your own services

## 1. Au cas où vous auriez oublié

Fait :smile:

## 2. Analyse des services existants

Un service c'est quoi concrètement ? C'est juste un processus, que le système lance, et dont il s'occupe après.

Il est défini dans un simple fichier texte, qui contient une info primordiale : la commande exécutée quand on "start" le service.

Il est possible de définir beaucoup d'autres paramètres optionnels afin que notre service s'exécute dans de bonnes conditions.

🌞 **Afficher le fichier de service SSH**

```bash
[hugoa@tp2linux ~]$ cat /usr/lib/systemd/system/sshd.service | grep ExecStart=
ExecStart=/usr/sbin/sshd -D $OPTIONS
```

🌞 **Afficher le fichier de service NGINX**

```bash
[hugoa@tp2linux ~]$ cat /usr/lib/systemd/system/nginx.service | grep ExecStart=
ExecStart=/usr/sbin/nginx
```

## 3. Création de service

🌞 **Créez le fichier `/etc/systemd/system/tp2_nc.service`**

```bash
[hugoa@tp2linux ~]$ echo $RANDOM
21527

[hugoa@tp2linux ~]$ sudo cat /etc/systemd/system/tp2_nc.service
service
[Unit]
Description=Super netcat tout fou

[Service]
ExecStart=/usr/bin/nc -l 21527
```

🌞 **Indiquer au système qu'on a modifié les fichiers de service**

```bash
[hugoa@tp2linux ~]$ sudo systemctl daemon-reload
```

🌞 **Démarrer notre service de ouf**

```bash
[hugoa@tp2linux ~]$ sudo systemctl start tp2_nc
```

🌞 **Vérifier que ça fonctionne**

```
[hugoa@tp2linux ~]$ sudo systemctl status tp2_nc
● tp2_nc.service - Super netcat tout fou
     Loaded: loaded (/etc/systemd/system/tp2_nc.service; static)
     Active: active (running) since Wed 2022-11-23 01:35:55 CET; 8s ago
   Main PID: 2110 (nc)
      Tasks: 1 (limit: 5904)
     Memory: 788.0K
        CPU: 2ms
     CGroup: /system.slice/tp2_nc.service
             └─2110 /usr/bin/nc -l 21527

Nov 23 01:35:55 tp2linux systemd[1]: Started Super netcat tout fou.
Nov 23 01:36:03 tp2linux systemd[1]: /etc/systemd/system/tp2_nc.service:1: Assignment outside of section. Ignoring.
```
```bash
[hugoa@tp2linux ~]$ ss -le | grep tp2_nc
tcp   LISTEN 0      10                                        0.0.0.0:21527                   0.0.0.0:*     ino:34455 sk:84 cgroup:/system.slice/tp2_nc.service <->
tcp   LISTEN 0      10                                           [::]:21527                      [::]:*     ino:34454 sk:86 cgroup:/system.slice/tp2_nc.service v6only:1 <->
```
- vérifer que juste ça marche en vous connectant au service depuis votre PC

```
?????????????????
```

🌞 **Les logs de votre service**

- mais euh, ça s'affiche où les messages envoyés par le client ? Dans les logs !
- `sudo journalctl -xe -u tp2_nc` pour visualiser les logs de votre service
- `sudo journalctl -xe -u tp2_nc -f ` pour visualiser **en temps réel** les logs de votre service
  - `-f` comme follow (on "suit" l'arrivée des logs en temps réel)
- dans le compte-rendu je veux
  - une commande `journalctl` filtrée avec `grep` qui affiche la ligne qui indique le démarrage du service
  - une commande `journalctl` filtrée avec `grep` qui affiche un message reçu qui a été envoyé par le client
  - une commande `journalctl` filtrée avec `grep` qui affiche la ligne qui indique l'arrêt du service

🌞 **Affiner la définition du service**

- faire en sorte que le service redémarre automatiquement s'il se termine
  - comme ça, quand un client se co, puis se tire, le service se relancera tout seul
  - ajoutez `Restart=always` dans la section `[Service]` de votre service
  - n'oubliez pas d'indiquer au système que vous avez modifié les fichiers de service :)