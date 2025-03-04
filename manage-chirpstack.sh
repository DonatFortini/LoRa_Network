#!/bin/bash

set -e

DOCKER_COMPOSE_FILE="docker-compose.yml"
BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
PROJECT_NAME="chirpstack"
CONFIG_DIR="./configuration"
MOSQUITTO_CONFIG_DIR="$CONFIG_DIR/mosquitto/config"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

check_requirements() {
    print_message "$BLUE" "Checking requirements..."

    if ! command -v docker &>/dev/null; then
        print_message "$RED" "Docker is not installed. Please install Docker first."
        exit 1
    fi

    if ! docker info &>/dev/null; then
        print_message "$RED" "Docker daemon is not running. Please start Docker first."
        exit 1
    fi

    if ! docker compose version &>/dev/null; then
        print_message "$RED" "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi

    print_message "$GREEN" "All requirements satisfied."
}

init() {
    print_message "$BLUE" "Initializing ChirpStack environment..."
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$MOSQUITTO_CONFIG_DIR"

    if [ ! -f "$MOSQUITTO_CONFIG_DIR/mosquitto.conf" ]; then
        print_message "$YELLOW" "Creating default mosquitto.conf..."
        cat >"$MOSQUITTO_CONFIG_DIR/mosquitto.conf" <<EOL
listener 1883
allow_anonymous true
EOL
    fi

    mkdir -p "$CONFIG_DIR/postgresql/initdb"

    if [ ! -f "$CONFIG_DIR/postgresql/initdb/001-chirpstack_extensions.sh" ]; then
        print_message "$YELLOW" "Creating PostgreSQL initialization script..."
        mkdir -p "$CONFIG_DIR/postgresql/initdb"
        cat >"$CONFIG_DIR/postgresql/initdb/001-chirpstack_extensions.sh" <<'EOL'
#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname="$POSTGRES_DB" <<-EOSQL
    create extension pg_trgm;
    create extension hstore;
EOSQL
EOL
        chmod +x "$CONFIG_DIR/postgresql/initdb/001-chirpstack_extensions.sh"
    fi

    mkdir -p "$CONFIG_DIR/chirpstack"
    mkdir -p "$CONFIG_DIR/chirpstack-gateway-bridge"

    print_message "$BLUE" "Pulling Docker images..."
    docker compose -f "$DOCKER_COMPOSE_FILE" pull

    print_message "$GREEN" "Initialization complete. You can now start the system with './manage-chirpstack.sh start'"
}

start() {
    print_message "$BLUE" "Starting ChirpStack services..."
    docker compose -f "$DOCKER_COMPOSE_FILE" -p "$PROJECT_NAME" up -d
    print_message "$GREEN" "ChirpStack services started successfully."
}

stop() {
    print_message "$BLUE" "Stopping ChirpStack services..."
    docker compose -f "$DOCKER_COMPOSE_FILE" -p "$PROJECT_NAME" down
    print_message "$GREEN" "ChirpStack services stopped successfully."
}

restart() {
    print_message "$BLUE" "Restarting ChirpStack services..."
    docker compose -f "$DOCKER_COMPOSE_FILE" -p "$PROJECT_NAME" restart
    print_message "$GREEN" "ChirpStack services restarted successfully."
}

reset() {
    print_message "$YELLOW" "WARNING: This will remove all containers and volumes!"
    read -p "Are you sure you want to continue? (y/n): " confirm

    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        print_message "$BLUE" "Resetting ChirpStack environment..."
        docker compose -f "$DOCKER_COMPOSE_FILE" -p "$PROJECT_NAME" down -v
        print_message "$GREEN" "ChirpStack environment reset successfully."
    else
        print_message "$BLUE" "Reset operation cancelled."
    fi
}

backup() {
    print_message "$BLUE" "Creating backup of ChirpStack volumes..."
    mkdir -p "$BACKUP_DIR"
    TEMP_BACKUP_DIR=$(mktemp -d)

    if ! docker compose -f "$DOCKER_COMPOSE_FILE" -p "$PROJECT_NAME" ps | grep -q "Up"; then
        print_message "$YELLOW" "Containers are not running. Starting them temporarily for backup..."
        docker compose -f "$DOCKER_COMPOSE_FILE" -p "$PROJECT_NAME" up -d
        sleep 5
    fi

    print_message "$BLUE" "Backing up PostgreSQL data..."
    docker exec "${PROJECT_NAME}-postgres-1" pg_dumpall -U chirpstack >"$TEMP_BACKUP_DIR/postgres_dump.sql"

    print_message "$BLUE" "Backing up Redis data..."
    docker exec "${PROJECT_NAME}-redis-1" redis-cli save
    docker cp "${PROJECT_NAME}-redis-1":/data/dump.rdb "$TEMP_BACKUP_DIR/redis_dump.rdb"

    print_message "$BLUE" "Backing up configuration files..."
    tar -czf "$TEMP_BACKUP_DIR/configuration.tar.gz" -C ./ configuration

    BACKUP_FILE="$BACKUP_DIR/chirpstack_backup_$TIMESTAMP.tar.gz"
    tar -czf "$BACKUP_FILE" -C "$TEMP_BACKUP_DIR" .

    rm -rf "$TEMP_BACKUP_DIR"

    print_message "$GREEN" "Backup created successfully: $BACKUP_FILE"
}

restore() {
    if [ -z "$2" ]; then
        print_message "$RED" "Error: No backup file specified."
        print_message "$YELLOW" "Usage: $0 restore <backup_file>"
        exit 1
    fi

    BACKUP_FILE="$2"

    if [ ! -f "$BACKUP_FILE" ]; then
        print_message "$RED" "Error: Backup file not found: $BACKUP_FILE"
        exit 1
    fi

    print_message "$BLUE" "Restoring from backup: $BACKUP_FILE"

    print_message "$BLUE" "Stopping all containers..."
    docker compose -f "$DOCKER_COMPOSE_FILE" -p "$PROJECT_NAME" down

    TEMP_RESTORE_DIR=$(mktemp -d)
    tar -xzf "$BACKUP_FILE" -C "$TEMP_RESTORE_DIR"

    # Reset volumes
    print_message "$BLUE" "Removing existing volumes..."
    docker volume rm chirpstack-postgresql-data chirpstack-redis-data chirpstack-mosquitto-data chirpstack-mosquitto-log || true

    # Restore configuration
    print_message "$BLUE" "Restoring configuration files..."
    tar -xzf "$TEMP_RESTORE_DIR/configuration.tar.gz" -C ./

    # Start containers
    print_message "$BLUE" "Starting containers..."
    docker compose -f "$DOCKER_COMPOSE_FILE" -p "$PROJECT_NAME" up -d

    # Wait for PostgreSQL to be ready
    print_message "$BLUE" "Waiting for PostgreSQL to be ready..."
    sleep 10

    # Restore PostgreSQL data
    print_message "$BLUE" "Restoring PostgreSQL data..."
    cat "$TEMP_RESTORE_DIR/postgres_dump.sql" | docker exec -i "${PROJECT_NAME}-postgres-1" psql -U chirpstack

    # Restore Redis data
    print_message "$BLUE" "Restoring Redis data..."
    docker cp "$TEMP_RESTORE_DIR/redis_dump.rdb" "${PROJECT_NAME}-redis-1":/data/dump.rdb
    docker exec "${PROJECT_NAME}-redis-1" redis-cli SHUTDOWN SAVE

    # Restart all services
    print_message "$BLUE" "Restarting all services..."
    docker compose -f "$DOCKER_COMPOSE_FILE" -p "$PROJECT_NAME" restart

    # Cleanup
    rm -rf "$TEMP_RESTORE_DIR"

    print_message "$GREEN" "Restore completed successfully."
}

status() {
    print_message "$BLUE" "ChirpStack service status:"
    docker compose -f "$DOCKER_COMPOSE_FILE" -p "$PROJECT_NAME" ps
}

help() {
    cat <<EOF
ChirpStack Management Script

Usage: $0 [command]

Commands:
  init      Initialize the ChirpStack environment
  start     Start all ChirpStack services
  stop      Stop all ChirpStack services
  restart   Restart all ChirpStack services
  status    Show status of all ChirpStack services
  reset     Remove all containers and volumes (destructive)
  backup    Create a backup of all volumes and configuration
  restore   Restore from a backup file
            Usage: $0 restore <backup_file>
EOF
}

# Main script execution
check_requirements

case "$1" in
"init")
    init
    ;;
"start")
    start
    ;;
"stop")
    stop
    ;;
"restart")
    restart
    ;;
"status")
    status
    ;;
"reset")
    reset
    ;;
"backup")
    backup
    ;;
"restore")
    restore "$@"
    ;;
"help" | "--help" | "-h" | "")
    help
    ;;
*)
    print_message "$RED" "Unknown command: $1"
    help
    exit 1
    ;;
esac
