# TP1 : Are you dead yet ?

## C'EST PARTI POUR TOUT PETER

### 1ère méthode :

On va supprimer les versions des kernel de notre OS Rocky de sortes que l'on ne puisse plus que lancer le mode rescue :

Rien de bien compliqué grâce à la commande :
```
uname -r 
```
qui nous permet de connaître la version de notre kernel
puis la commande :
```
kernel-install remove KERNEL-VERSION
```
il suffit de remplacer KERNEL-VERSION par celle obtenue grâce `uname -r`

P.S. Dans mon cas, j'avais deux versions : 5.14.0-70.13.1.el9_0.x86_64 et 5.14.0-70.26.1.el9_0.x86_64 donc j'ai dû enlever les deux.

### 2ème méthode :

J'ai nommé cette méthode le "Grand Vidage". On va tout simplement VIDER la partition sda1 du disque dur. C'est la partition utilisée pour l'os, donc ça peut être sympa de voir ce que ça fait quand y'a plus que des zéros dedans ^^

Pour ce faire, il suffit de taper cette commande :

```
dd if=/dev/zero of=/dev/sda1
```

`if=/dev/zero` permet de lire le fichier ``zero`` contenu dans le dossier ``/dev``

`of=/dev/sda1` permet d'écrire dans le fichier `sda1`

Maintenant, plus qu'à fermer la VM et la rouvrir et surprise, nous voici en mode rescue. 

Good Luck 

### 3ème méthode :

Adieu BASH

Je me suis demandé ce que ça ferait si on enlève le shell par défaut de Rocky...

```
rm /bin/bash
```

Eh bien, on ne peut même plus se connecter en root

### 4ème méthode :

Qu'est-ce qu'il se passe si je déplace un fichier aussi important que ``login`` dans mon `/home` par exemple ?

```
cd ..
```
puis 

```
mv /bin/login /home/hugoa
```

puis un petit reboot et impossible de se connecter en root 

