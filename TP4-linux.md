# TP 4 : Real services

# Partie 1 : Partitionnement du serveur de stockage

🌞 **Partitionner le disque à l'aide de LVM**

- créer un *physical volume (PV)* : le nouveau disque ajouté à la VM

```
[hugoa@tp4storage ~]$ sudo pvcreate /dev/sdb
  Physical volume "/dev/sdb" successfully created.
```

- créer un nouveau *volume group (VG)*

```
[hugoa@tp4storage ~]$ sudo vgcreate storage /dev/sdb
  Volume group "storage" successfully created
```

- créer un nouveau *logical volume (LV)* : ce sera la partition utilisable

```
[hugoa@tp4storage ~]$ sudo lvcreate -l 100%FREE storage -n storage_tro_bi1
  Logical volume "storage_tro_bi1" created.
```

🌞 **Formater la partition**

- vous formaterez la partition en ext4 (avec une commande `mkfs`)

```
[hugoa@tp4storage ~]$ mkfs -t ext4 /dev/storage/storage_tro_bi1
mke2fs 1.46.5 (30-Dec-2021)
mkfs.ext4: Permission denied while trying to determine filesystem size
[hugoa@tp4storage ~]$ sudo mkfs -t ext4 /dev/storage/storage_tro_bi1
mke2fs 1.46.5 (30-Dec-2021)
Creating filesystem with 523264 4k blocks and 130816 inodes
Filesystem UUID: 002a4366-299a-49b2-b0c5-521381d09638
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376, 294912

Allocating group tables: done
Writing inode tables: done
Creating journal (8192 blocks): done
Writing superblocks and filesystem accounting information: done
```

🌞 **Monter la partition**

- montage de la partition (avec la commande `mount`)

```
[hugoa@tp4storage ~]$ sudo mkdir /mnt/storage
[hugoa@tp4storage ~]$ sudo mount /dev/storage/storage_tro_bi1 /mnt/storage

[hugoa@tp4storage ~]$ df -h | grep /mnt/storage
/dev/mapper/storage-storage_tro_bi1  2.0G   24K  1.9G   1% /mnt/storage

[hugoa@tp4storage ~]$ sudo cat /dev/mapper/storage-storage_tro_bi1
��3f��������c��c��S���c
                                   <�k*Cf)�I���R�Ж82
                                                        �+kI����K�Z@
                                                                         ��c
�   FH��!�^�P,���d �~����������~����       ���W�
��2��.p�~�������v�
```
- définir un montage automatique de la partition (fichier `/etc/fstab`)

```
[hugoa@tp4storage ~]$ sudo umount /mnt/storage

[hugoa@tp4storage ~]$ sudo mount -av
/                        : ignored
/boot                    : already mounted
none                     : ignored
mount: /mnt/storage does not contain SELinux labels.
       You just mounted a file system that supports labels which does not
       contain labels, onto an SELinux box. It is likely that confined
       applications will generate AVC messages and not be allowed access to
       this file system.  For more details see restorecon(8) and mount(8).
/mnt/storage             : successfully mounted

[hugoa@tp4storage ~]$ df -h | grep /mnt/storage
/dev/mapper/storage-storage_tro_bi1  2.0G   24K  1.9G   1% /mnt/storage
```

# Partie 2 : Serveur de partage de fichiers

🌞 **Donnez les commandes réalisées sur le serveur NFS `storage.tp4.linux`**

```
[hugoa@tp4storage ~]$ sudo mkdir /mnt/storage/site_web_1 -p
[hugoa@tp4storage ~]$ sudo mkdir /mnt/storage/site_web_2 -p
[hugoa@tp4storage ~]$ sudo chown nobody /mnt/storage/site_web_1
[hugoa@tp4storage ~]$ sudo chown nobody /mnt/storage/site_web_2

[hugoa@tp4storage ~]$ sudo cat /etc/exports
/mnt/storage/site_web_1 10.4.4.21(rw,sync,no_subtree_check)
/mnt/storage/site_web_2 10.4.4.21(rw,sync,no_subtree_check)

[hugoa@tp4storage ~]$ sudo systemctl enable nfs-server
Created symlink /etc/systemd/system/multi-user.target.wants/nfs-server.service → /usr/lib/systemd/system/nfs-server.service.
[hugoa@tp4storage ~]$ sudo systemctl start nfs-server
[hugoa@tp4storage ~]$ sudo systemctl status nfs-server | grep Active
     Active: active (exited) since Tue 2022-12-06 14:22:48 CET; 1min 25s ago

[hugoa@tp4storage ~]$ sudo firewall-cmd --list-all | grep services
  services: cockpit dhcpv6-client mountd nfs rpc-bind ssh

```

🌞 **Donnez les commandes réalisées sur le client NFS `web.tp4.linux`**

```
[hugoa@tp4web ~]$ sudo mkdir -p /var/www/site_web_1
[hugoa@tp4web ~]$ sudo mkdir -p /var/www/site_web_2
[hugoa@tp4web ~]$ sudo mount 10.4.4.22:/mnt/storage/site_web_1 /var/www/site_web_1
[hugoa@tp4web ~]$ sudo mount 10.4.4.22:/mnt/storage/site_web_2 /var/www/site_web_2

[hugoa@tp4web ~]$ df -h | grep 10.4.4.22
10.4.4.22:/mnt/storage/site_web_1  2.0G     0  1.9G   0% /var/www/site_web_1
10.4.4.22:/mnt/storage/site_web_2  2.0G     0  1.9G   0% /var/www/site_web_2

[hugoa@tp4web ~]$ sudo cat /etc/fstab | grep 10.4.4.22
10.4.4.22:/mnt/storage/site_web_1 /var/www/site_web_1 nfs defaults 0 0
10.4.4.22:/mnt/storage/site_web_2 /var/www/site_web_2 nfs defaults 0 0
```

# Partie 3 : Serveur web

## 2. Install

🖥️ **VM web.tp4.linux**

🌞 **Installez NGINX**

```
[hugoa@tp4web ~]$ sudo dnf install nginx -y
```

## 3. Analyse

🌞 **Analysez le service NGINX**

- avec une commande `ps`, déterminer sous quel utilisateur tourne le processus du service NGINX

```
[hugoa@tp4web ~]$ ps -ef | grep nginx
root        1188       1  0 15:00 ?        00:00:00 nginx: master process /usr/sbin/nginx
nginx       1189    1188  0 15:00 ?        00:00:00 nginx: worker process
hugoa       1226     887  0 15:02 pts/0    00:00:00 grep --color=auto nginx
```

- avec une commande `ss`, déterminer derrière quel port écoute actuellement le serveur web

```
[hugoa@tp4web ~]$ sudo ss -alnp | grep nginx
tcp   LISTEN 0      511                                       0.0.0.0:80
      0.0.0.0:*     users:(("nginx",pid=1189,fd=6),("nginx",pid=1188,fd=6))

tcp   LISTEN 0      511                                          [::]:80
         [::]:*     users:(("nginx",pid=1189,fd=7),("nginx",pid=1188,fd=7))
```

- en regardant la conf, déterminer dans quel dossier se trouve la racine web

```
[hugoa@tp4web ~]$ cat /etc/nginx/nginx.conf | grep root
        root         /usr/share/nginx/html;
```

- inspectez les fichiers de la racine web, et vérifier qu'ils sont bien accessibles en lecture par l'utilisateur qui lance le processus

```
[hugoa@tp4web ~]$ ls -al /usr/share/nginx/html
total 12
drwxr-xr-x. 3 root root  143 Dec  6 14:57 .
drwxr-xr-x. 4 root root   33 Dec  6 14:57 ..
-rw-r--r--. 1 root root 3332 Oct 31 16:35 404.html
-rw-r--r--. 1 root root 3404 Oct 31 16:35 50x.html
drwxr-xr-x. 2 root root   27 Dec  6 14:57 icons
lrwxrwxrwx. 1 root root   25 Oct 31 16:37 index.html -> ../../testpage/index.html
-rw-r--r--. 1 root root  368 Oct 31 16:35 nginx-logo.png
lrwxrwxrwx. 1 root root   14 Oct 31 16:37 poweredby.png -> nginx-logo.png
lrwxrwxrwx. 1 root root   37 Oct 31 16:37 system_noindex_logo.png -> ../../pixmaps/system-noindex-logo.png
```

## 4. Visite du service web

**Et ça serait bien d'accéder au service non ?** Genre c'est un serveur web. On veut voir un site web !

🌞 **Configurez le firewall pour autoriser le trafic vers le service NGINX**

```
[hugoa@tp4web ~]$ sudo firewall-cmd --add-port=80/tcp --permanent
success
[hugoa@tp4web ~]$ sudo firewall-cmd --reload
success
[hugoa@tp4web ~]$ sudo firewall-cmd --list-all | grep 80
  ports: 22/tcp 80/tcp
```

🌞 **Accéder au site web**

```
PS C:\Users\hugoa> curl http://10.4.4.21


StatusCode        : 200
StatusDescription : OK
Content           : <!doctype html>
                    <html>
                      <head>
                        <meta charset='utf-8'>
                        <meta name='viewport' content='width=device-width, initial-scale=1'>
                        <title>HTTP Server Test Page powered by: Rocky Linux</title>
                       ...
RawContent        : HTTP/1.1 200 OK
                    Connection: keep-alive
                    Accept-Ranges: bytes
                    Content-Length: 7620
                    Content-Type: text/html
                    Date: Tue, 06 Dec 2022 14:33:15 GMT
                    ETag: "62e17e64-1dc4"
                    Last-Modified: Wed, 27 Jul 202...
Forms             : {}
Headers           : {[Connection, keep-alive], [Accept-Ranges, bytes], [Content-Length, 7620], [Content-Type, text/html]...}
Images            : {@{innerHTML=; innerText=; outerHTML=<IMG alt="[ Powered by Rocky Linux ]" src="icons/poweredby.png">;
                    outerText=; tagName=IMG; alt=[ Powered by Rocky Linux ]; src=icons/poweredby.png}, @{innerHTML=; innerText=;
                    outerHTML=<IMG src="poweredby.png">; outerText=; tagName=IMG; src=poweredby.png}}
InputFields       : {}
Links             : {@{innerHTML=<STRONG>Rocky Linux website</STRONG>; innerText=Rocky Linux website; outerHTML=<A
                    href="https://rockylinux.org/"><STRONG>Rocky Linux website</STRONG></A>; outerText=Rocky Linux website;
                    tagName=A; href=https://rockylinux.org/}, @{innerHTML=Apache Webserver</STRONG>; innerText=Apache Webserver;
                    outerHTML=<A href="https://httpd.apache.org/">Apache Webserver</STRONG></A>; outerText=Apache Webserver;
                    tagName=A; href=https://httpd.apache.org/}, @{innerHTML=Nginx</STRONG>; innerText=Nginx; outerHTML=<A
                    href="https://nginx.org">Nginx</STRONG></A>; outerText=Nginx; tagName=A; href=https://nginx.org},
                    @{innerHTML=<IMG alt="[ Powered by Rocky Linux ]" src="icons/poweredby.png">; innerText=; outerHTML=<A
                    id=rocky-poweredby href="https://rockylinux.org/"><IMG alt="[ Powered by Rocky Linux ]"
                    src="icons/poweredby.png"></A>; outerText=; tagName=A; id=rocky-poweredby; href=https://rockylinux.org/}...}
ParsedHtml        : mshtml.HTMLDocumentClass
RawContentLength  : 7620



```

🌞 **Vérifier les logs d'accès**

```
[hugoa@tp4web ~]$ sudo cat /var/log/nginx/access.log | tail -n 3
10.4.4.1 - - [06/Dec/2022:15:28:07 +0100] "GET /favicon.ico HTTP/1.1" 404 3332 "http://10.4.4.21/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36 Edg/107.0.1418.62" "-"
10.4.4.1 - - [06/Dec/2022:15:32:29 +0100] "GET / HTTP/1.1" 200 7620 "-" "Mozilla/5.0 (Windows NT; Windows NT 10.0; fr-FR) WindowsPowerShell/5.1.22000.832" "-"
10.4.4.1 - - [06/Dec/2022:15:33:15 +0100] "GET / HTTP/1.1" 200 7620 "-" "Mozilla/5.0 (Windows NT; Windows NT 10.0; fr-FR) WindowsPowerShell/5.1.22000.832" "-"
```

## 5. Modif de la conf du serveur web

🌞 **Changer le port d'écoute**

- une simple ligne à modifier, vous me la montrerez dans le compte rendu

```
[hugoa@tp4web ~]$ sudo cat /etc/nginx/nginx.conf | grep listen
        listen       8080;
```

- redémarrer le service pour que le changement prenne effet

```
[hugoa@tp4web ~]$ sudo systemctl restart nginx
[hugoa@tp4web ~]$ sudo systemctl status nginx | grep Active
     Active: active (running) since Tue 2022-12-06 15:44:48 CET; 24s ago
```

- prouvez-moi que le changement a pris effet avec une commande `ss`

```
[hugoa@tp4web ~]$ sudo ss -alnp | grep nginx
tcp   LISTEN 0      511                                       0.0.0.0:8080
    0.0.0.0:*     users:(("nginx",pid=1404,fd=6),("nginx",pid=1403,fd=6))

tcp   LISTEN 0      511                                          [::]:80
       [::]:*     users:(("nginx",pid=1404,fd=7),("nginx",pid=1403,fd=7))

```

- n'oubliez pas de fermer l'ancien port dans le firewall, et d'ouvrir le nouveau

```
[hugoa@tp4web ~]$ sudo firewall-cmd --add-port=8080/tcp --permanent
success
[hugoa@tp4web ~]$ sudo firewall-cmd --remove-port=80/tcp --permanent
success
[hugoa@tp4web ~]$ sudo firewall-cmd --reload
success
[hugoa@tp4web ~]$ sudo firewall-cmd --list-all | grep 8080
  ports: 22/tcp 8080/tcp
```

- prouvez avec une commande `curl` sur votre machine que vous pouvez désormais visiter le port 8080

```
PS C:\Users\hugoa> curl http://10.4.4.21:8080


StatusCode        : 200
StatusDescription : OK
Content           : <!doctype html>
                    <html>
                      <head>
                        <meta charset='utf-8'>
                        <meta name='viewport' content='width=device-width,
                    initial-scale=1'>
                        <title>HTTP Server Test Page powered by: Rocky Linux</title>
                       ...
RawContent        : HTTP/1.1 200 OK
                    Connection: keep-alive
                    Accept-Ranges: bytes
                    Content-Length: 7620
                    Content-Type: text/html
                    Date: Tue, 06 Dec 2022 14:54:55 GMT
                    ETag: "62e17e64-1dc4"
                    Last-Modified: Wed, 27 Jul 202...
Forms             : {}
Headers           : {[Connection, keep-alive], [Accept-Ranges, bytes], [Content-Length,
                    7620], [Content-Type, text/html]...}
Images            : {@{innerHTML=; innerText=; outerHTML=<IMG alt="[ Powered by Rocky
                    Linux ]" src="icons/poweredby.png">; outerText=; tagName=IMG; alt=[
                    Powered by Rocky Linux ]; src=icons/poweredby.png}, @{innerHTML=;
                    innerText=; outerHTML=<IMG src="poweredby.png">; outerText=;
                    tagName=IMG; src=poweredby.png}}
InputFields       : {}
Links             : {@{innerHTML=<STRONG>Rocky Linux website</STRONG>; innerText=Rocky
                    Linux website; outerHTML=<A
                    href="https://rockylinux.org/"><STRONG>Rocky Linux
                    website</STRONG></A>; outerText=Rocky Linux website; tagName=A;
                    href=https://rockylinux.org/}, @{innerHTML=Apache Webserver</STRONG>;
                    innerText=Apache Webserver; outerHTML=<A
                    href="https://httpd.apache.org/">Apache Webserver</STRONG></A>;
                    outerText=Apache Webserver; tagName=A;
                    href=https://httpd.apache.org/}, @{innerHTML=Nginx</STRONG>;
                    innerText=Nginx; outerHTML=<A
                    href="https://nginx.org">Nginx</STRONG></A>; outerText=Nginx;
                    tagName=A; href=https://nginx.org}, @{innerHTML=<IMG alt="[ Powered by
                    Rocky Linux ]" src="icons/poweredby.png">; innerText=; outerHTML=<A
                    id=rocky-poweredby href="https://rockylinux.org/"><IMG alt="[ Powered
                    by Rocky Linux ]" src="icons/poweredby.png"></A>; outerText=;
                    tagName=A; id=rocky-poweredby; href=https://rockylinux.org/}...}
ParsedHtml        : mshtml.HTMLDocumentClass
RawContentLength  : 7620



```

---

🌞 **Changer l'utilisateur qui lance le service**

- pour ça, vous créerez vous-même un nouvel utilisateur sur le système : `web`

```
[hugoa@tp4web ~]$ sudo useradd web -d /home/web -p web
[hugoa@tp4web ~]$ sudo cat /etc/passwd | grep /home/web
web:x:1001:1001::/home/web:/bin/bash
```

- modifiez la conf de NGINX pour qu'il soit lancé avec votre nouvel utilisateur

```
[hugoa@tp4web ~]$ sudo cat /etc/nginx/nginx.conf | grep 'user web'
user web;
```

- n'oubliez pas de redémarrer le service pour que le changement prenne effet

```
[hugoa@tp4web ~]$ sudo systemctl restart nginx
```

- vous prouverez avec une commande `ps` que le service tourne bien sous ce nouveau utilisateur

```
[hugoa@tp4web ~]$ sudo ps -ef | grep nginx
root        1523       1  0 16:20 ?        00:00:00 nginx: master process /usr/sbin/nginx
web         1524    1523  0 16:20 ?        00:00:00 nginx: worker process
hugoa       1576     887  0 16:22 pts/0    00:00:00 grep --color=auto nginx
```

---

**Il est temps d'utiliser ce qu'on a fait à la partie 2 !**

🌞 **Changer l'emplacement de la racine Web**

- configurez NGINX pour qu'il utilise une autre racine web que celle par défaut

```
[hugoa@tp4web ~]$ sudo cat /var/www/site_web_1/index.html
<! DOCTYPE html>
<html>
        <head>
                <title>Ma grosse page</title>
        </head>
        <body>
        <h1>Ma grosse page</h1>
        <p>Trop bien \^o^/</p>
        </body>
</html>

[hugoa@tp4web ~]$ sudo cat /etc/nginx/nginx.conf | grep root
        root         /var/www/site_web_1/;
```

- prouvez avec un `curl` depuis votre hôte que vous accédez bien au nouveau site

```
PS C:\Users\hugoa> curl http://10.4.4.21:8080


StatusCode        : 200
StatusDescription : OK
Content           : <! DOCTYPE html>
                    <html>
                            <head>
                                    <title>Ma grosse page</title>
                            </head>
                            <body>
                            <h1>Ma grosse page</h1>
                            <p>Trop bien \^o^/</p>
                            </body>
                    </htm...
RawContent        : HTTP/1.1 200 OK
                    Connection: keep-alive
                    Accept-Ranges: bytes
                    Content-Length: 203
                    Content-Type: text/html
                    Date: Tue, 06 Dec 2022 15:49:27 GMT
                    ETag: "638f6349-cb"
                    Last-Modified: Tue, 06 Dec 2022 1...
Forms             : {}
Headers           : {[Connection, keep-alive], [Accept-Ranges, bytes], [Content-Length,
                    203], [Content-Type, text/html]...}
Images            : {}
InputFields       : {}
Links             : {}
ParsedHtml        : mshtml.HTMLDocumentClass
RawContentLength  : 203



```
## 6. Deux sites web sur un seul serveur

🌞 **Repérez dans le fichier de conf**

```
[hugoa@tp4web ~]$ sudo cat /etc/nginx/nginx.conf | grep conf.d/
    include /etc/nginx/conf.d/*.conf;
```

🌞 **Créez le fichier de configuration pour le premier site**

```
[hugoa@tp4web ~]$ cat /etc/nginx/conf.d/site_web_1.conf
    server {
        listen       8080;
        listen       [::]:80;
        server_name  _;
        root         /var/www/site_web_1/;

        # Load configuration files for the default server block.
        include /etc/nginx/default.d/*.conf;

        error_page 404 /404.html;
        location = /404.html {
        }

        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
        }
    }
```

🌞 **Créez le fichier de configuration pour le deuxième site**

```
[hugoa@tp4web ~]$ cat /etc/nginx/conf.d/site_web_2.conf
    server {
        listen       8888;
        listen       [::]:80;
        server_name  _;
        root         /var/www/site_web_1/index.html;

        # Load configuration files for the default server block.
        include /etc/nginx/default.d/*.conf;

        error_page 404 /404.html;
        location = /404.html {
        }

        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
        }
    }
```

🌞 **Prouvez que les deux sites sont disponibles**

```
# premier site
PS C:\Users\hugoa> curl http://10.4.4.21:8080


StatusCode        : 200
StatusDescription : OK
Content           : <! DOCTYPE html>
                    <html>
                            <head>
                                    <title>Ma grosse page</title>
                            </head>
                            <body>
                            <h1>Ma grosse page</h1>
                            <p>Trop bien \^o^/</p>
                            </body>
                    </htm...
RawContent        : HTTP/1.1 200 OK
                    Connection: keep-alive
                    Accept-Ranges: bytes
                    Content-Length: 203
                    Content-Type: text/html
                    Date: Tue, 06 Dec 2022 16:25:13 GMT
                    ETag: "638f6349-cb"
                    Last-Modified: Tue, 06 Dec 2022 1...
Forms             : {}
Headers           : {[Connection, keep-alive], [Accept-Ranges, bytes], [Content-Length,
                    203], [Content-Type, text/html]...}
Images            : {}
InputFields       : {}
Links             : {}
ParsedHtml        : mshtml.HTMLDocumentClass
RawContentLength  : 203


# deuxieme site
PS C:\Users\hugoa> curl http://10.4.4.21:8888


StatusCode        : 200
StatusDescription : OK
Content           : toto

RawContent        : HTTP/1.1 200 OK
                    Connection: keep-alive
                    Accept-Ranges: bytes
                    Content-Length: 5
                    Content-Type: text/html
                    Date: Tue, 06 Dec 2022 16:25:37 GMT
                    ETag: "638f6b89-5"
                    Last-Modified: Tue, 06 Dec 2022 16:1...
Forms             : {}
Headers           : {[Connection, keep-alive], [Accept-Ranges, bytes], [Content-Length,
                    5], [Content-Type, text/html]...}
Images            : {}
InputFields       : {}
Links             : {}
ParsedHtml        : mshtml.HTMLDocumentClass
RawContentLength  : 5



```