#!/bin/bash

# Volume name list and corresponding archive names
VOLUMES=("mariadb_data" "influxdb_data" "grafana_data")
ARCHIVE_NAMES=("mariadb" "influx" "grafana")

# Loop over each volume and archive
for i in "${!VOLUMES[@]}"
do
    volume="${VOLUMES[$i]}"
    archive="${ARCHIVE_NAMES[$i]}"
    docker run --rm -v "lora_network_${volume}:/volume" -v "$(pwd):/backup" busybox sh -c "cd /volume && tar -zxvf /backup/${archive}.tar.gz"
done
