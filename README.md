# JeuWeb Push Server
JeuWeb Push Server est un service WebSocket pour les créateurs de jeux de la communauté JeuWeb

Le serveur est écrit en Elixir à l'aide du framework [Phoenix](https://www.phoenixframework.org/). Le service est constitué d'une API HTTP et d'un serveur de WebSocket proposant des canaux nommés.

Une instance est hébergée sur [push.jeuweb.org](https://push.jeuweb.org) mais le serveur peut être installé sur sa propre machine.

***

## Table of contents

- [Fonctionnement général](#fonctionnement-général)
- [Obtenir un compte](#obtenir-un-compte)
- [Web hooks](#web-hooks)
- [Générer un token de connexion](#générer-un-token-de-connexion)
- [Liens utiles](#liens-utiles)


## Fonctionnement général

JeuWeb Pusher Server permet aux développeurs d'envoyer des données à leurs utilisateurs en temps réel et à l'initiative du serveur (contrairement à une requête Ajax, qui est à l'initative du client).

Les membres demandent à utiliser les services auprès d'un admin (Sephi-Chan) qui lui crée un compte (nom d'utilisateur et mot de passe).

Le développeur intègre le client JavaScript sur son site connecte ses utilisateurs à un ou plusieurs canaux (par exemple un canal pour l'utilisateur, un pour le salon de discussion, un pour l'équipe, etc.). Le développeur définit pour chaque canal du code à exécuter lors de la réception de chaque message.

Depuis le code de son jeu (quel que soit le langage, un client est fourni pour PHP mais n'importe quel client HTTP fait l'affaire), le développeur peut envoyer des messages sur le ou les canaux de son choix. Si un joueur est connecté à ce canal, le client JavaScript exécutera le code pour ce canal.


## Obtenir un compte

Jusqu'à ce que la première version soit finalisée, l'obtention d'un compte JWP se fait auprès d'un administrateur de JeuWeb. Il est utile de disposer d'un compte par environnement (développement et production).
Le développeur reçoit alors différentes informations :

- un `app_id` pour identifier l'application de manière unique. Par exemple `jeuweb-dev` ou `jeuweb-prod` ;
- un `app_secret` confidentiel qui permet de générer le token de connexion aux channels ;
- un `email` qui sert d'identifiant d'accès au site web de JWP ;
- un `password` confidentiel qui permet de se connecter au site site web de JWP ;
- une `api_key` confidentielle qui permet de s'authentifier auprès de l'API de JWP ;
- un `webhooks_endpoint` qui est une URL vers une page du jeu qui recevra les requêtes HTTP de JWP, par exemple `http://jeuweb.org/jwp_webooks_endpoint.php` ;
- une `webhooks_key` confidentielle que JWP enverra dans ses requêtes HTTP pour que le développeur soit certain que la requête provient bien de JWP ;


## Web hooks

Quand un visiteur se connecte à un canal JWP, il est connecté au serveur WebSocket de JWP et le site ne reçoit aucune information. Il ne reçoit pas non plus d'information quand un joueur se déconnecte d'un canal.

Le mécanisme de web hooks permet au développeur d'être notifié de ces événements. JWP lui envoie alors une requête HTTP POST à l'URL `webhooks_endpoint`. Pour que le développeur s'assure que la requête vient bien de JWP, le header `authorization` a pour valeur `webhooks_key`, que seuls lui et JWP connaissent.

Le corps de cette requête est un objet JSON contenant les clés suivantes :
- le `channel` contient le nom du canal auquel l'utilisateur s'est connecté (par exemple `lobby` ou `user:42`)  ;
- l'événement `event` contient `join` si l'utilisateur s'est connecté au canal ou `leave` s'il l'a quitté ;
- l'information `socket_id` qui a été transmise lors de la connexion au canal, il s'agit généralement d'un moyen d'identfier le joueur.

Un cas d'utilisation de ces web hooks est de signaler aux autres utilisateur (par un push) qu'un joueur s'est connecté ou déconnecté.

Par défaut, ces web hooks ne sont pas activés. Le développeur peut les activer pour un canal donné au moment de générer un token d'autorisation auprès de JWP. Il est rarement utile de les activer pour plusieurs canaux et cela peut générer un grand nombre de requêtes vers le site.


## Générer un token de connexion

Pour pouvoir se connecter à un canal, le client JavaScript doit envoyer au serveur WebSocket un token. Cela permet au server WebSocket d'accepter uniquement les connexions explicitement autorisées par le développeur.

Pour chaque canal, l'application doit générer un token contenant plusieurs informations et le transmettre au code JavaScript afin qu'il puisse être envoyé au serveur WebSocket.


## Liens utiles

* [jwp-server](https://github.com/JeuWeb/jwp-server) : le serveur lui-même
* [jwp-php-client](https://github.com/JeuWeb/jwp-php-client) : le cient PHP
* [jwp-browser-client](https://github.com/JeuWeb/jwp-browser-client) : le client JavaScript pour le navigateur
* [jwp-php-example-app](https://github.com/JeuWeb/jwp-php-example-app) : une application d'exemple en PHP
