#!/bin/bash
tor &
sleep 30
if [[ ! -d ~/.tari ]]; then
  tari_base_node --init --create-id
fi
tari_base_node
