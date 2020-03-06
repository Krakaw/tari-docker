#!/bin/bash

docker-compose up -d tor
IPADDRESS=$(docker inspect -f "{{ .NetworkSettings.Networks.tarinetwork.IPAddress }}" $(docker-compose ps -q tor))
cat template_config.toml | sed "s/__REPLACE_ME__/$IPADDRESS/" > tari_config/config.toml
docker-compose up wait
docker-compose run tari
