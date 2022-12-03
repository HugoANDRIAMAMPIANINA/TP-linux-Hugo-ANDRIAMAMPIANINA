# TP 3 : We do a little scripting

# I. Script carte d'identité

## Rendu

📁 **Fichier `/srv/idcard/idcard.sh`**

**[/srv/idcard/idcard.sh](scripts/idcard.sh)**

🌞 **Vous fournirez dans le compte-rendu**, en plus du fichier, **un exemple d'exécution avec une sortie**, dans des balises de code.

```
[root@tp3linux ~]# /srv/idcard/idcard.sh
Machine name : tp3linux
OS Rocky Linux 9.0 and kernel version is 5.14.0-70.30.1.el9_0.x86_64
IP : 10.2.2.3
RAM : 658M memory available on 960M total memory
Disk : 5.0G space left
Top 5 processes by RAM usage :
  - /usr/bin/python3 -s /usr/sbin/firewalld --nofork --nopid
  - /usr/sbin/NetworkManager --no-daemon
  - /usr/lib/systemd/systemd --switched-root --system --deserialize 30
  - /usr/lib/systemd/systemd --user
  - sshd: root [priv]
Listening ports :
  - 323 udp : chronyd
  - 22 tcp : sshd

Here is your random cat : ./cat.png
```


# II. Script youtube-dl

## Rendu

📁 **Le script `/srv/yt/yt.sh`**

**[/srv/yt/yt.sh](scripts/yt.sh)**

📁 **Le fichier de log `/var/log/yt/download.log`**, avec au moins quelques lignes

**[/var/log/yt/download.log](scripts/download.log)**

🌞 Vous fournirez dans le compte-rendu, en plus du fichier, **un exemple d'exécution avec une sortie**, dans des balises de code.

```
[hugoa@tp3linux ~]$ /srv/yt/yt.sh https://www.youtube.com/watch?v=Tq5oInDSb-M
Video https://www.youtube.com/watch?v=Tq5oInDSb-M was downloaded.
File path : /srv/yt/downloads/Pub Audible Nicolas Sarkozy/Pub Audible Nicolas Sarkozy.mp4

[hugoa@tp3linux ~]$ /srv/yt/yt.sh https://www.youtube.com/watch?v=eT5tsFA6pCg
Video https://www.youtube.com/watch?v=eT5tsFA6pCg was downloaded.
File path : /srv/yt/downloads/Maité et william saurin/Maité et william saurin.mp4

[hugoa@tp3linux ~]$ /srv/yt/yt.sh https://www.youtube.com/watch?v=8hmOaKlDY1Q
Video https://www.youtube.com/watch?v=8hmOaKlDY1Q was downloaded.
File path : /srv/yt/downloads/Peter Parker's Shout/Peter Parker's Shout.mp4

[hugoa@tp3linux ~]$ /srv/yt/yt.sh https://www.youtube.com/watch?v=pW_Z67R53XA
Video https://www.youtube.com/watch?v=pW_Z67R53XA was downloaded.
File path : /srv/yt/downloads/Stranger Cats/Stranger Cats.mp4
```

# III. MAKE IT A SERVICE

## Rendu

**ATTENTION : pour que le programme marche, il faut rendre `yt` propriétaire des fichiers `/tmp/title` et `/tmp/ext`**

📁 **Le script `/srv/yt/yt-v2.sh`**

**[yt-v2.sh](scripts/yt-v2.sh)**

📁 **Fichier `/etc/systemd/system/yt.service`**

**[yt.service](scripts/yt.service)**

🌞 Vous fournirez dans le compte-rendu, en plus des fichiers :

- un `systemctl status yt` quand le service est en cours de fonctionnement

```
[hugoa@tp3linux ~]$ systemctl status yt
● yt.service - Mon super service qui telecharge des videos youtube \^o^/
     Loaded: loaded (/etc/systemd/system/yt.service; disabled; vendor preset: disabled)
     Active: active (running) since Sat 2022-12-03 18:25:01 CET; 4min 13s ago
   Main PID: 977 (yt-v2.sh)
      Tasks: 2 (limit: 5904)
     Memory: 1.3M
        CPU: 5.785s
     CGroup: /system.slice/yt.service
             ├─ 977 /bin/bash /srv/yt/yt-v2.sh
             └─1076 sleep 5

Dec 03 18:25:01 tp3linux systemd[1]: Started Mon super service qui telecharge des videos youtube \^o^/.
Dec 03 18:26:15 tp3linux yt-v2.sh[977]: Video https://www.youtube.com/watch?v=eT5tsFA6pCg was downloaded.
Dec 03 18:26:15 tp3linux yt-v2.sh[977]: File path : /srv/yt/downloads/Maité et william saurin/Maité et william saurin.mp4
```

- un extrait de `journalctl -xe -u yt`

```
[hugoa@tp3linux ~]$ sudo journalctl -xe -u yt
Dec 03 18:25:01 tp3linux systemd[1]: Started Mon super service qui telecharge des videos youtube \^o^/.
░░ Subject: A start job for unit yt.service has finished successfully
░░ Defined-By: systemd
░░ Support: https://access.redhat.com/support
░░
░░ A start job for unit yt.service has finished successfully.
░░
░░ The job identifier is 786.
Dec 03 18:26:15 tp3linux yt-v2.sh[977]: Video https://www.youtube.com/watch?v=eT5tsFA6pCg was downloaded.
Dec 03 18:26:15 tp3linux yt-v2.sh[977]: File path : /srv/yt/downloads/Maité et william saurin/Maité et william saurin.mp4
```