# tari-docker

A starting point to get the Tari base node to run in docker.

#### Create `tor_control_auth` password
1. Set tor_control_auth in template_config.toml
2. Generate a hash of that password `docker-compose run tor tor --hash-password password`
3. Paste the output into ./config/tor/torrc `HashedControlPassword "generated_hash"`

### Start
```bash
# Add your seed_peers to template_config.toml
./start.sh
```

On first run it will run `tari_base_node --create_id` each subsequent run is just `tari_base_node`

