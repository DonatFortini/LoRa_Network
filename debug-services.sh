#!/bin/bash

# ChirpStack Debug Script
# Provides detailed information for troubleshooting ChirpStack services

set -e

# Configuration
DOCKER_COMPOSE_FILE="docker-compose.yml"
PROJECT_NAME="chirpstack"
LOG_DIR="./debug_logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DEBUG_LOG="$LOG_DIR/chirpstack_debug_${TIMESTAMP}.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print section header
print_header() {
    echo -e "\n${MAGENTA}========== $1 ==========${NC}" | tee -a "$DEBUG_LOG"
}

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}" | tee -a "$DEBUG_LOG"
}

# Function to run a command and log output
run_command() {
    local description=$1
    local command=$2

    print_header "$description"
    echo -e "${CYAN}$ $command${NC}" | tee -a "$DEBUG_LOG"
    eval "$command" 2>&1 | tee -a "$DEBUG_LOG"
}

# Create log directory
mkdir -p "$LOG_DIR"

# Start logging
print_message "$GREEN" "Starting ChirpStack debug at $(date)"
print_message "$BLUE" "Debug logs will be saved to $DEBUG_LOG"

# System information
print_header "SYSTEM INFORMATION"
run_command "Operating System" "uname -a"
run_command "CPU Info" "cat /proc/cpuinfo | grep 'model name' | head -1"
run_command "Memory Info" "free -h"
run_command "Disk Space" "df -h"

# Docker info
print_header "DOCKER INFORMATION"
run_command "Docker Version" "docker --version"
run_command "Docker Compose Version" "docker compose version"
run_command "Docker Info" "docker info"

# Check if Docker services are running
print_header "CHIRPSTACK CONTAINER STATUS"
run_command "Container Status" "docker compose -f $DOCKER_COMPOSE_FILE -p $PROJECT_NAME ps"

# List all Docker networks
print_header "DOCKER NETWORKS"
run_command "Docker Networks" "docker network ls"
run_command "ChirpStack Network Details" "docker network inspect ${PROJECT_NAME}_default"

# List all Docker volumes
print_header "DOCKER VOLUMES"
run_command "Docker Volumes" "docker volume ls | grep chirpstack"
run_command "Volume Details" "for vol in \$(docker volume ls -q | grep chirpstack); do echo \"--- \$vol ---\"; docker volume inspect \$vol; done"

# Network connectivity tests
print_header "NETWORK CONNECTIVITY TESTS"
run_command "Mosquitto Connectivity" "docker exec ${PROJECT_NAME}-chirpstack-1 ping -c 3 mosquitto || echo 'Ping failed'"
run_command "Redis Connectivity" "docker exec ${PROJECT_NAME}-chirpstack-1 ping -c 3 redis || echo 'Ping failed'"
run_command "PostgreSQL Connectivity" "docker exec ${PROJECT_NAME}-chirpstack-1 ping -c 3 postgres || echo 'Ping failed'"

# Port checks
print_header "OPEN PORTS"
run_command "Listening Ports" "docker exec ${PROJECT_NAME}-chirpstack-1 netstat -tulpn || echo 'netstat not available'"

# Get logs for each container
print_header "CONTAINER LOGS"

containers=(
    "chirpstack"
    "chirpstack-gateway-bridge"
    "chirpstack-gateway-bridge-basicstation"
    "chirpstack-rest-api"
    "postgres"
    "redis"
    "mosquitto"
)

for container in "${containers[@]}"; do
    print_header "${container^^} LOGS (last 50 lines)"
    run_command "${container} Logs" "docker compose -f $DOCKER_COMPOSE_FILE -p $PROJECT_NAME logs --tail=50 $container"
done

# PostgreSQL check
print_header "POSTGRESQL DATABASE CHECK"
run_command "PostgreSQL Status" "docker exec ${PROJECT_NAME}-postgres-1 pg_isready -U chirpstack"
run_command "PostgreSQL Databases" "docker exec ${PROJECT_NAME}-postgres-1 psql -U chirpstack -c '\l'"
run_command "PostgreSQL Tables" "docker exec ${PROJECT_NAME}-postgres-1 psql -U chirpstack -c '\dt' chirpstack"

# Redis check
print_header "REDIS CHECK"
run_command "Redis Status" "docker exec ${PROJECT_NAME}-redis-1 redis-cli ping"
run_command "Redis Info" "docker exec ${PROJECT_NAME}-redis-1 redis-cli info | grep version"
run_command "Redis Memory" "docker exec ${PROJECT_NAME}-redis-1 redis-cli info memory | grep used_memory_human"

# Mosquitto check
print_header "MOSQUITTO CHECK"
run_command "Mosquitto Config" "docker exec ${PROJECT_NAME}-mosquitto-1 cat /mosquitto/config/mosquitto.conf"
run_command "MQTT Topics" "docker exec ${PROJECT_NAME}-mosquitto-1 mosquitto_sub -v -t '#' -C 1 -W 5 || echo 'No MQTT messages received in 5 seconds'"

# ChirpStack configuration check
print_header "CHIRPSTACK CONFIGURATION"
run_command "Main Config" "docker exec ${PROJECT_NAME}-chirpstack-1 cat /etc/chirpstack/chirpstack.toml"
run_command "Region Config" "docker exec ${PROJECT_NAME}-chirpstack-1 cat /etc/chirpstack/region_eu868.toml"

# Gateway Bridge configuration check
print_header "GATEWAY BRIDGE CONFIGURATION"
run_command "GW Bridge Config" "docker exec ${PROJECT_NAME}-chirpstack-gateway-bridge-1 cat /etc/chirpstack-gateway-bridge/chirpstack-gateway-bridge.toml"
run_command "GW Bridge BS Config" "docker exec ${PROJECT_NAME}-chirpstack-gateway-bridge-basicstation-1 cat /etc/chirpstack-gateway-bridge/chirpstack-gateway-bridge-basicstation-eu868.toml"

# Container resource usage
print_header "CONTAINER RESOURCE USAGE"
run_command "Container Stats" "docker stats --no-stream --format 'table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}'"

# API endpoint check
print_header "API ENDPOINT CHECK"
run_command "API Status" "curl -s -o /dev/null -w '%{http_code}' http://localhost:8080 || echo 'API not available'"
run_command "REST API Status" "curl -s -o /dev/null -w '%{http_code}' http://localhost:8090 || echo 'REST API not available'"

# Execution complete
print_message "$GREEN" "Debug information collection completed at $(date)"
print_message "$BLUE" "Debug log saved to: $DEBUG_LOG"
print_message "$YELLOW" "You can share this log file when seeking support."

cat <<EOF

${GREEN}===== DEBUG SUMMARY =====${NC}

Debug information has been collected and saved to:
$DEBUG_LOG

This file contains detailed information about your ChirpStack deployment including:
- System information
- Docker configuration
- Container status and logs
- Network connectivity
- Database status
- Configuration files
- Resource usage

If you're experiencing issues with your ChirpStack deployment,
please share this file when seeking support.

EOF
