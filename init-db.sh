#!/bin/bash
set -e

# Script d'initialisation pour PostgreSQL
# Ce script s'exécutera lors du premier démarrage du conteneur PostgreSQL

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
  -- Créer l'extension pg_trgm requise par ChirpStack
  CREATE EXTENSION IF NOT EXISTS pg_trgm;
  
  -- Créer l'extension hstore
  CREATE EXTENSION IF NOT EXISTS hstore;
  
  -- Créer l'extension postgis (optionnel, pour les fonctionnalités de géolocalisation)
  -- CREATE EXTENSION IF NOT EXISTS postgis;
EOSQL

echo "Extensions PostgreSQL installées avec succès."
