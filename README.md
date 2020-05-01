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


## Cookbook

### Comment puis-je utiliser le service en PHP ?

Côté HTML, vous devez inclure le script `jwp.min.js` avant le code de l'application. Puis utiliser l'objet `jwp` :

```js
// Connexion au serveur de WebSocket.
var socket = jwp.connect('ws://push.jeuweb.org/socket', jwp.xhrParams('/jwp/authorize-socket.php'));
```

Quand ce code est exécuté par le navigateur de vos visiteurs, il exécutera une requête Ajax en POST vers votre site (à l'adresse `/jwp/authorize-socket.php`, que vous pouvez modifier à votre convenance) pour autoriser (ou non) la connexion.

L'application doit donc gérer cette requête POST en délivrant une réponse en JSON.

```php
$socketId = $_SESSION['user_id']; // Vous pouvez utiliser l'ID de votre utilisateur, un UUID, un nombre aléatoire…
$jwp = new Jwp\Client(new Jwp\Auth('JWP_APP_ID', 'JWP_API_KEY', 'JWP_SECRET')); // On instancie le client JWP.
$json = json_decode(file_get_contents('php://input'), true); // On récupère le JSON envoyé dans la requête Ajax.
$token = $jwp->authenticateSocket($socketID, 60); // On génère un token qui sera valide 60 secondes.

exit(json_encode([
  'status' => 'ok',
  'data' => [
    'auth' => $token,
    'app_id' => 'JWP_APP_ID'
  ]
]));
```

Si la connexion doit être refusée, retournez un objet JSON de la forme `{ "status": "error" }`.

Après l'appel à `jwp.connect`, vous pouvez utiliser `jwp.channel` pour vous connecter à un canal. Vous pouvez le faire autant de fois que vous le désirez.

```js
// Connexion à un canal et défintion de quelques callbacks pour les événéments "new-message" et "buzz".
var channel = socket.channel("lobby", jwp.fetchParams('/jwp/authorize-channel.php'));
```

Là aussi, il faut gérer la requête POST qui arrive en Ajax sur `/jwp/authorize-channel.php`. C'est à vous de décider  si un utilisateur peut bien avoir accès au canal auquel il essaye de se connecter.

```php
$socketId = $_SESSION['user_id'];
$jwp = new Jwp\Client(new Jwp\Auth('JWP_APP_ID', 'JWP_API_KEY', 'JWP_SECRET')); // On instancie le client JWP.
$channel = $json['channel_name']; // Le nom du canal demandé.
$options = [ // Les différentes options activées pour ce canal. Lisez bien la documentation.
  'presence_track' => true, // Pour garder une liste des utilisateurs connectés à un canal.
  'presence_diffs' => true, // Pour tenir à jour la liste des utilisateurs connectés à un canal.
  'notify_joins' => true, // Pour envoyer une requête vers votre serveur quand un utilisateur rejoint un canal.
  'notify_leaves' => true, // Pour envoyer une requête vers votre serveur quand un utilisateur quitte un canal.
];
$token = $jwp->authenticateChannel($socketID, $channel, [], $options);

exit(json_encode([
  'status' => 'ok',
  'data' => [
    'auth' => $token,
    'channel_name' => 'JWP_APP_ID'
  ]
]));
```

L'appel à `jwp.channel` retourne un objet que vous pouvez utiliser pour vous abonner aux événements et définir un callback pour y réagir.

```js
channel.join();
channel.on("new-message", function(data) { appendMessage(data.message, data.username); });
channel.on("buzz", function(data) { playSound("buzz.mp3"); });
```

Ce code sert à définir quoi faire quand un événément est envoyé sur le canal. Vous pouvez ouvrir autant de canaux et vous abonner à autant d'événements que vous souhaitez.

Vous pouvez par exemple avoir un canal réservé à votre utilisateur. Un usage fréquent est de nommer ce canal `user:USER_ID`.

Enfin, pour envoyer des données depuis votre application PHP :

```php
$jwp = new Jwp\Client(new Jwp\Auth('JWP_APP_ID', 'JWP_API_KEY', 'JWP_SECRET'));
$jwp->push("lobby", 'new-message', [ 'message' => $message, 'username' => $username ]);
```


## Liens utiles

* [jwp-server](https://github.com/JeuWeb/jwp-server) : le serveur lui-même
* [jwp-php-client](https://github.com/JeuWeb/jwp-php-client) : le cient PHP
* [jwp-browser-client](https://github.com/JeuWeb/jwp-browser-client) : le client JavaScript pour le navigateur
* [jwp-php-example-app](https://github.com/JeuWeb/jwp-php-example-app) : une application d'exemple en PHP
