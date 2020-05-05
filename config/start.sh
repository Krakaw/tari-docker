#!/bin/bash
#
# Script to start tor
#
tor --allow-missing-torrc --ignore-missing-torrc \
  --clientonly 1 --socksport 9050 --controlport 127.0.0.1:9051 \
  --log "notice stdout" --clientuseipv6 1 &

sleep 30

tari_base_node
