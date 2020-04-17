# JeuWeb Push Server
JeuWeb Push Server est un service WebSocket pour les créateurs de jeux de la communauté JeuWeb

Le serveur est écrit en Elixir à l'aide du framework [Phoenix](https://www.phoenixframework.org/). Le service est constitué d'une API HTTP et d'un serveur de WebSocket proposant des canaux nommés.

Une instance est hébergée sur [push.jeuweb.org](https://push.jeuweb.org) mais le serveur peut être installé sur sa propre machine.


## Fonctionnement général

JeuWeb Pusher Server permet aux créateurs de jeux d'envoyer des données à leurs joueurs en temps réel et à l'initiative du serveur (contrairement à une requête Ajax qui est à l'initative du client).

Les membres demandent à utiliser les services auprès d'un admin (Sephi-Chan) qui lui crée un compte (nom d'utilisateur et mot de passe).

Le créateur intègre le client JavaScript sur son jeu et connecte ses joueurs à un ou plusieurs canaux (par exemple un canal pour l'utilisateur, un canal pour le salon de discussion, un canal pour l'équipe, etc.) et écrire du code à exécuter à la réception des messages sur ce canal.

Depuis le code de son jeu (quel que soit le langage, un client est fourni pour PHP mais n'importe quel client HTTP fait l'affaire), le créateur peut envoyer des messages sur le ou les canaux de son choix. Si un joueur est connecté à ce canal, le client JavaScript exécutera le code pour ce canal.


## Liens utiles
* [jwp-server](https://github.com/JeuWeb/jwp-server) : le serveur lui-même
* [jwp-php-client](https://github.com/JeuWeb/jwp-php-client) : le cient PHP
* [jwp-browser-client](https://github.com/JeuWeb/jwp-browser-client) : le client JavaScript pour le navigateur
* [jwp-php-example-app](https://github.com/JeuWeb/jwp-php-example-app) : une application d'exemple en PHP
