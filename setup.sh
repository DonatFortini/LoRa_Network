#!/bin/bash
# Script pour initialiser et déployer ChirpStack
# Usage: ./setup.sh [init|start|stop|restart|logs]

# Couleurs pour les messages
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Fonction pour afficher un message
message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

# Fonction pour afficher un avertissement
warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Fonction pour afficher une erreur
error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Fonction d'initialisation
init() {
    message "Initialisation de l'environnement ChirpStack..."

    # Création des répertoires nécessaires
    message "Création des répertoires de données..."
    mkdir -p data/postgres
    mkdir -p data/redis
    mkdir -p data/mosquitto/data
    mkdir -p data/mosquitto/log
    mkdir -p data/lorawan-devices
    mkdir -p chirpstack

    # Vérification des fichiers de configuration
    if [ ! -f "chirpstack/chirpstack.toml" ]; then
        warning "Fichier chirpstack.toml non trouvé. Veuillez le créer manuellement."
    fi

    if [ ! -f "mosquitto.conf" ]; then
        warning "Fichier mosquitto.conf non trouvé. Veuillez le créer manuellement."
    fi

    # Permissions des scripts
    message "Configuration des permissions..."
    chmod +x init-db.sh

    message "Initialisation terminée. Vous pouvez maintenant démarrer ChirpStack avec './setup.sh start'"
}

# Fonction de démarrage
start() {
    message "Démarrage des services ChirpStack..."
    docker compose up -d
    message "ChirpStack démarré. Accès à l'interface: http://localhost:8080 (admin/admin)"
}

# Fonction d'arrêt
stop() {
    message "Arrêt des services ChirpStack..."
    docker compose down
    message "ChirpStack arrêté."
}

# Fonction de redémarrage
restart() {
    message "Redémarrage des services ChirpStack..."
    docker compose down
    docker compose up -d
    message "ChirpStack redémarré."
}

# Fonction d'affichage des logs
logs() {
    message "Affichage des logs ChirpStack..."
    docker compose logs -f
}

# Vérification des arguments
case "$1" in
init)
    init
    ;;
start)
    start
    ;;
stop)
    stop
    ;;
restart)
    restart
    ;;
logs)
    logs
    ;;
*)
    echo "Usage: $0 [init|start|stop|restart|logs]"
    exit 1
    ;;
esac

exit 0
