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

YES. Yet again. **On va en faire un [service](../../cours/notions/serveur/README.md#ii-service).**

L'idée :

➜ plutôt que d'appeler la commande à la main quand on veut télécharger une vidéo, **on va créer un service qui les téléchargera pour nous**

➜ le service devra **lire en permanence dans un fichier**

- s'il trouve une nouvelle ligne dans le fichier, il vérifie que c'est bien une URL de vidéo youtube
  - si oui, il la télécharge, puis enlève la ligne
  - sinon, il enlève juste la ligne

➜ **qui écrit dans le fichier pour ajouter des URLs ? Bah vous !**

- vous pouvez écrire une liste d'URL, une par ligne, et le service devra les télécharger une par une

---

Pour ça, procédez par étape :

- **partez de votre script précédent** (gardez une copie propre du premier script, qui doit être livré dans le dépôt git)
  - le nouveau script s'appellera `yt-v2.sh`
- **adaptez-le pour qu'il lise les URL dans un fichier** plutôt qu'en argument sur la ligne de commande
- **faites en sorte qu'il tourne en permanence**, et vérifie le contenu du fichier toutes les X secondes
  - boucle infinie qui :
    - lit un fichier
    - effectue des actions si le fichier n'est pas vide
    - sleep pendant une durée déterminée
- **il doit marcher si on précise une vidéo par ligne**
  - il les télécharge une par une
  - et supprime les lignes une par une
- **une fois que tout ça fonctionne, enfin, créez un service** qui lance votre script :
  - créez un fichier `/etc/systemd/system/yt.service`. Il comporte :
    - une brève description
    - un `ExecStart` pour indiquer que ce service sert à lancer votre script
    - une clause `User=` pour indiquer quel utilisateur doit lancer le script

```bash
[Unit]
Description=<Votre description>

[Service]
ExecStart=<Votre script>
User=<User>

[Install]
WantedBy=multi-user.target
```

> Pour rappel, après la moindre modification dans le dossier `/etc/systemd/system/`, vous devez exécuter la commande `sudo systemctl daemon-reload` pour dire au système de lire les changements qu'on a effectué.

Vous pourrez alors interagir avec votre service à l'aide des commandes habituelles `systemctl` :

- `systemctl status yt`
- `sudo systemctl start yt`
- `sudo systemctl stop yt`

![Now witness](./pics/now_witness.png)

## Rendu

📁 **Le script `/srv/yt/yt-v2.sh`**

📁 **Fichier `/etc/systemd/system/yt.service`**

🌞 Vous fournirez dans le compte-rendu, en plus des fichiers :

- un `systemctl status yt` quand le service est en cours de fonctionnement
- un extrait de `journalctl -xe -u yt`

> Hé oui les commandes `journalctl` fonctionnent sur votre service pour voir les logs ! Et vous devriez constater que c'est vos `echo` qui pop. En résumé, **le STDOUT de votre script, c'est devenu les logs du service !**

🌟**BONUS** : get fancy. Livrez moi un gif ou un [asciinema](https://asciinema.org/) (PS : c'est le feu asciinema) de votre service en action, où on voit les URLs de vidéos disparaître, et les fichiers apparaître dans le fichier de destination

# IV. Bonus

Quelques bonus pour améliorer le fonctionnement de votre script :

➜ **en accord avec les règles de [ShellCheck](https://www.shellcheck.net/)**

- bonnes pratiques, sécurité, lisibilité

➜  **fonction `usage`**

- le script comporte une fonction `usage`
- c'est la fonction qui est appelée lorsque l'on appelle le script avec une erreur de syntaxe
- ou lorsqu'on appelle le `-h` du script

➜ **votre script a une gestion d'options :**

- `-q` pour préciser la qualité des vidéos téléchargées (on peut choisir avec `youtube-dl`)
- `-o` pour préciser un dossier autre que `/srv/yt/`
- `-h` affiche l'usage

➜ **si votre script utilise des commandes non-présentes à l'installation** (`youtube-dl`, `jq` éventuellement, etc.)

- vous devez TESTER leur présence et refuser l'exécution du script

➜  **si votre script a besoin de l'existence d'un dossier ou d'un utilisateur**

- vous devez tester leur présence, sinon refuser l'exécution du script

➜ **pour le téléchargement des vidéos**

- vérifiez à l'aide d'une expression régulière que les strings saisies dans le fichier sont bien des URLs de vidéos Youtube