# ChirpStack LoRaWAN Network Server

Ce dépôt propose une configuration Docker complète pour déployer et gérer une instance de ChirpStack (EU868), basée sur la configuration originale v4. Le projet inclut également un script de gestion pour simplifier les opérations courantes. Ce fork ajoute la persistance des volumes ainsi qu'un système de sauvegarde et de débogage.

## Composants

Le déploiement inclut les services suivants :

- **ChirpStack** : Serveur réseau LoRaWAN principal
- **ChirpStack Gateway Bridge** : Pont entre les passerelles LoRaWAN et le serveur réseau
- **ChirpStack Gateway Bridge BasicStation** : Support pour les passerelles utilisant le protocole BasicStation
- **ChirpStack REST API** : API REST pour interagir avec ChirpStack
- **PostgreSQL** : Base de données pour stocker les informations des appareils et des applications
- **Redis** : Stockage de données pour les files d'attente et le cache
- **Mosquitto** : Broker MQTT pour la communication entre les composants

## Prérequis

- Docker
- Docker Compose
- Git (pour le clonage du dépôt)
- Bash

## Installation

1. Clonez ce dépôt :

   ```bash
   git clone https://github.com/DonatFortini/LoRa_Network.git
   cd LoRa_Network
   ```

2. Rendez le script de gestion exécutable :

   ```bash
   chmod +x manage-chirpstack.sh
   ```

3. Initialisez l'environnement :

   ```bash
   ./manage-chirpstack.sh init
   ```

4. Démarrez les services :
   ```bash
   ./manage-chirpstack.sh start
   ```

## Utilisation du script de gestion

Le script `manage-chirpstack.sh` fournit plusieurs commandes pour gérer votre déploiement :

- **init** : Initialise l'environnement en créant les répertoires et fichiers de configuration nécessaires
- **start** : Démarre tous les services
- **stop** : Arrête tous les services
- **restart** : Redémarre tous les services
- **status** : Affiche l'état de tous les conteneurs
- **reset** : Supprime tous les conteneurs et volumes (destructif, avec confirmation)
- **backup** : Crée une sauvegarde complète de toutes les données et configurations
- **restore <fichier_backup>** : Restaure depuis un fichier de sauvegarde

Exemples d'utilisation :

```bash
# Voir l'état des services
./manage-chirpstack.sh status

# Créer une sauvegarde
./manage-chirpstack.sh backup

# Restaurer depuis une sauvegarde
./manage-chirpstack.sh restore ./backups/chirpstack_backup_20250304_123456.tar.gz
```

## Structure des volumes

Les données persistantes sont stockées dans les volumes Docker suivants :

- **chirpstack-postgresql-data** : Données PostgreSQL
- **chirpstack-redis-data** : Données Redis
- **chirpstack-mosquitto-data** : Données Mosquitto
- **chirpstack-mosquitto-log** : Logs Mosquitto

## Configuration

Les fichiers de configuration se trouvent dans le répertoire `configuration` :

- **chirpstack/** : Configuration du serveur ChirpStack
- **chirpstack-gateway-bridge/** : Configuration du Bridge Gateway
- **mosquitto/config/** : Configuration du broker MQTT
- **postgresql/initdb/** : Scripts d'initialisation de PostgreSQL

### Configuration Mosquitto

Le broker MQTT est configuré avec une authentification anonyme par défaut :

```
listener 1883
allow_anonymous true
```

Pour renforcer la sécurité en production, vous devriez configurer l'authentification.

## Accès à l'interface web

L'interface web de ChirpStack est accessible à l'adresse : http://localhost:8080

Utilisateur par défaut :

- **Nom d'utilisateur** : admin
- **Mot de passe** : admin

## Interface API REST

L'API REST de ChirpStack est disponible à l'adresse : http://localhost:8090

## Sauvegardes

Les sauvegardes sont stockées dans le répertoire `backups/` et contiennent :

- Dump complet de la base de données PostgreSQL
- Données Redis
- Tous les fichiers de configuration

## Gestion des passerelles

Ce déploiement prend en charge :

- Les passerelles utilisant le protocole Semtech UDP sur le port 1700
- Les passerelles BasicStation sur le port 3001

## Configuration régionale

La configuration par défaut est pour la région EU868. Pour d'autres régions, modifiez les fichiers de configuration appropriés dans le répertoire `configuration/`.

## Sécurité

Pour un déploiement en production, assurez-vous de :

1. Configurer des mots de passe forts pour PostgreSQL et l'interface utilisateur
2. Configurer l'authentification MQTT
3. Activer TLS/SSL pour les connexions
4. Limiter l'exposition des ports

## Ressources supplémentaires

- [Documentation officielle de ChirpStack](https://www.chirpstack.io/docs/)
- [GitHub ChirpStack](https://github.com/chirpstack/chirpstack)
