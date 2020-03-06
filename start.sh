#!/bin/bash

check_password() {
  password=$( grep -oP  "^tor_control_auth\s*=\s*\"password=(.*?)\"" template_config.toml  | sed -n 's/^.*password=\(.*\)\"/\1/p' )
  if [ "password" == "${password}" ]; then
    RED='\033[0;31m'
    NC='\033[0m' # No Color
    echo -e "${RED}You are using the default tor_control_auth password, you should REALLY change this.${NC}"
  fi
}

check_password
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
