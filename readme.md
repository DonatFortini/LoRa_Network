# ChirpStack Docker Setup

Configuration Docker pour déployer ChirpStack avec volumes locaux pour la persistance et le versionnement via Git.

## Structure du projet

```
chirpstack-docker/
├── .gitignore                # Configuration Git (quels fichiers ignorer)
├── README.md                 # Ce fichier de documentation
├── docker-compose.yml        # Configuration Docker Compose
├── setup.sh                  # Script d'initialisation et de gestion
├── init-db.sh                # Script d'initialisation PostgreSQL
├── mosquitto.conf            # Configuration pour le broker MQTT
├── chirpstack/               # Configuration ChirpStack
│   └── chirpstack.toml       # Fichier de configuration principal
└── data/                     # Données persistantes (créé automatiquement)
    ├── postgres/             # Données PostgreSQL
    ├── redis/                # Données Redis
    ├── mosquitto/            # Données et logs Mosquitto
    └── lorawan-devices/      # Définitions d'appareils LoRaWAN
```

## Prérequis

- Docker et Docker Compose installés
- Git installé (pour le clonage et la gestion du dépôt)

## Installation

1. Clonez ce dépôt sur votre machine locale ou serveur:

```bash
git clone <URL_DU_REPO> chirpstack-docker
cd chirpstack-docker
```

2. Initialisez l'environnement:

```bash
chmod +x setup.sh
./setup.sh init
```

3. Démarrez ChirpStack:

```bash
./setup.sh start
```

4. Accédez à l'interface web:
   - URL: http://localhost:8080 (ou l'adresse IP de votre serveur)
   - Utilisateur: admin
   - Mot de passe: admin

## Utilisation

Le script `setup.sh` permet de gérer facilement votre installation:

- `./setup.sh init`: Initialise l'environnement (création des répertoires, etc.)
- `./setup.sh start`: Démarre les services ChirpStack
- `./setup.sh stop`: Arrête les services
- `./setup.sh restart`: Redémarre les services
- `./setup.sh logs`: Affiche les logs en temps réel

## Configuration avancée

### Personnalisation de ChirpStack

Pour modifier la configuration de ChirpStack, éditez le fichier `chirpstack/chirpstack.toml`.

### Personnalisation du broker MQTT

Pour modifier la configuration de Mosquitto, éditez le fichier `mosquitto.conf`.

### Sécurité

Pour un environnement de production:

1. Modifiez les mots de passe par défaut dans `docker-compose.yml`
2. Configurez l'authentification pour MQTT dans `mosquitto.conf`
3. Activez TLS/SSL pour les communications

## Sauvegarde et restauration

Les données sont stockées dans le répertoire `./data/` et peuvent être sauvegardées et versionnées selon vos besoins.

Pour une sauvegarde complète:

```bash
# Arrêtez les services
./setup.sh stop

# Sauvegardez le répertoire data
tar -czvf chirpstack-backup-$(date +%Y%m%d).tar.gz data/

# Redémarrez les services
./setup.sh start
```

## Mise à jour

Pour mettre à jour les images Docker:

```bash
docker compose pull
./setup.sh restart
```
