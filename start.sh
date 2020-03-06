#!/bin/bash

docker-compose up -d tor
IPADDRESS=$(docker inspect -f "{{ .NetworkSettings.Networks.tarinetwork.IPAddress }}" $(docker-compose ps -q tor))
cat template_config.toml | sed "s/__TOR_CONTAINER_IP__/$IPADDRESS/" > data/tari/config.toml
docker-compose up wait

#Check if we have the run --create_id
if [ ! -f "data/tari/rincewind/node_id.json" ]; then
  echo "This is the first run, execute create_id"
  docker-compose run tari tari_base_node --create_id
else
  docker-compose run tari
fi
