#!/bin/bash

CONFIG_FILE=./template_config.toml
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color
check_password() {
  password=$(grep -oP "^tor_control_auth\s*=\s*\"password=(.*?)\"" $CONFIG_FILE | sed -n 's/^.*password=\(.*\)\"/\1/p')
  if [ "mypassword" == "${password}" ]; then
    echo -e "${RED}You are using the default tor_control_auth password, you should REALLY change this.${NC}"
  fi
}

fetch_peers() {
  peers_string=$(grep -oP "^\s*peer_seeds\s*=\s*.*" $CONFIG_FILE | sed -n 's/^.*\[\(.*\)\].*$/\1/p' | tr -d '"')
  IFS=', ' read -r -a peer_array <<<"$peers_string"
  peer_length=${#peer_array[@]}
  if [ $peer_length -eq 0 ]; then
    echo -e "${RED}You have not set the peer_seeds config. Aborting${NC}"
    exit 1
  fi
  echo "Checking peers, use -ss to skip: $peers_string"
  for element in "${peer_array[@]}"; do
    address="$(echo "$element" | cut -f3 -d/ | cut -f1 -d:).onion"
    port="$(echo "$element" | cut -f3 -d/ | cut -f2 -d:)"
    check_peers "$address" "$port" && echo -e "${GREEN}$address:$port is UP! :)${NC}" || echo -e "${RED}$address:$port is DOWN! :(${NC}"
  done
}

check_peers() {
  docker-compose run nc -w 1 -v -X5 -x tor:9050 "$1" "$2" 2>&1 > /dev/null
}

CHECK_PEERS=1
CHECK_PASSWORD=1
while [ "$1" != "" ]; do
  case $1 in
  -ss | --skip-peer-check)
    CHECK_PEERS=0
    ;;
  -sp | --skip-password-check)
    CHECK_PASSWORD=0
    ;;
  -c | --config)
    shift
    CONFIG_FILE=$1
    ;;
  esac
  shift
done


[[ $CHECK_PASSWORD -eq 1 ]] && check_password

cp "$CONFIG_FILE" data/config.toml
docker-compose up -d tor
docker-compose up wait

[[ $CHECK_PEERS -eq 1 ]] && fetch_peers

#Check if we have the run --create_id
if [ ! -f "data/tari/rincewind/node_id.json" ]; then
  echo "This is the first run, execute create_id"
  docker-compose run tari --create_id
else
  echo "Starting Tari base node"
  docker-compose up tari
fi
