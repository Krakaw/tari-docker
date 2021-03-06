#!/usr/bin/env bash

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

spin() {
  spinner="/|\\-/|\\-"
  while :; do
    for i in $(seq 0 7); do
      echo -n "${spinner:$i:1}"
      echo -en "\010"
      sleep 1
    done
  done
}

fetch_peers() {
  peers_string=$(grep -oP "^\s*peer_seeds\s*=\s*.*" $CONFIG_FILE | sed -n 's/^.*\[\(.*\)\].*$/\1/p' | tr -d '"')
  IFS=', ' read -r -a peer_array <<<"$peers_string"
  peer_length=${#peer_array[@]}
  if [ $peer_length -eq 0 ]; then
    echo -e "${RED}You have not set the peer_seeds config. Aborting${NC}"
    exit 1
  fi
  echo "Checking peers, use -ss to skip:"
  for element in "${peer_array[@]}"; do
    address="$(echo "$element" | cut -f3 -d/ | cut -f1 -d:).onion"
    port="$(echo "$element" | cut -f3 -d/ | cut -f2 -d:)"

    echo -n "$address:$port "

    #Add a spinner
    spin &
    SPIN_PID=$!
    # Kill the spinner on any signal, including our own exit.
    trap "kill -9 $SPIN_PID 2>&1> /dev/null ;" SIGTERM #$(seq 0 15)
    # Check the peers on tor
    check_peers "$address" "$port" && echo -e "${GREEN}is UP! :)${NC}" || echo -e "${RED}is DOWN! :(${NC}"
    # Kill the spinner
    kill -9 "$SPIN_PID"
    # Clean up the kill message
    wait "$SPIN_PID" 2>/dev/null
    # Unset the trap
    trap - $(seq 0 15)
  done
}

parse_config(){
    [[ -f $1 ]] || { echo "$1 is not a file." >&2;return 1;}
    if [[ -n $2 ]]
    then
        local -n config_array=$2
    else
        local -n config_array=config
    fi
    declare -Ag ${!config_array} || return 1
    local line key value section_regex entry_regex
    section_regex="^[[:blank:]]*\[([[:alpha:]_][[:alnum:]_]*)\][[:blank:]]*(#.*)?$"
    entry_regex="^[[:blank:]]*([[:alpha:]_][[:alnum:]_]*)[[:blank:]]*=[[:blank:]]*('[^']+'|\"[^\"]+\"|[^#[:blank:]]+)[[:blank:]]*(#.*)*$"
    while read -r line
    do
        [[ -n $line ]] || continue
        [[ $line =~ $section_regex ]] && {
            local -n config_array=${BASH_REMATCH[1]}
            declare -Ag ${!config_array} || return 1
            continue
        }
        [[ $line =~ $entry_regex ]] || continue
        key=${BASH_REMATCH[1]}
        value=${BASH_REMATCH[2]#[\'\"]} # strip quotes
        value=${value%[\'\"]}
        config_array["${key}"]="${value}"
    done < "$1"
}

# Usage: parse_config_vars <file>
# No arrays, just read variables individually.
# Preexisting variables will be overwritten.

parse_config_vars(){
    [[ -f $1 ]] || { echo "$1 is not a file." >&2;return 1;}
    local line key value entry_regex
    entry_regex="^[[:blank:]]*([[:alpha:]_][[:alnum:]_]*)[[:blank:]]*=[[:blank:]]*('[^']+'|\"[^\"]+\"|[^#[:blank:]]+)[[:blank:]]*(#.*)*$"
    while read -r line
    do
        [[ -n $line ]] || continue
        [[ $line =~ $entry_regex ]] || continue
        key=${BASH_REMATCH[1]}
        value=${BASH_REMATCH[2]#[\'\"]} # strip quotes
        value=${value%[\'\"]}
        declare -g "${key}"="${value}"
    done < "$1"
}


check_peers() {
  docker-compose run nc -w 1 -v -X5 -x tor:9050 "$1" "$2" 2>&1 >/dev/null
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

cp "$CONFIG_FILE" data/tari/config.toml
docker-compose up -d tor
docker-compose up wait

[[ $CHECK_PEERS -eq 1 ]] && fetch_peers

#Check if we have the run --create-id
if [ ! -f "data/tari/rincewind/node_id.json" ]; then
  echo "This is the first run, execute create_id"
  docker-compose run tari  tari_base_node --create-id
else
  echo "Starting Tari base node"
  docker-compose run tari
fi
