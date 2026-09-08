# Syncthing observability

This adds Syncthing metrics, alerts, and logs for the Linux stack host and a
push-only Grafana Alloy client on macOS. No API key or real hostname belongs in
Git.

## Secrets and local values

On the forge host, set these in the monitoring Compose environment:

```dotenv
SYNCTHING_API_KEY_FILE=./secrets/syncthing-api-key
SYNCTHING_RELAY_PORT=18384
SYNCTHING_FORGE_HOST_LABEL=<forge-host>
```

Create `services/monitoring/secrets/syncthing-api-key` locally with only the
value of `<apikey>` from `~/.local/state/syncthing/config.xml`, no surrounding
XML. Set mode `0600`. The path is supplied to Docker Compose and mounted at
`/run/secrets/syncthing_api_key`; it must remain untracked.

The `syncthing-relay` container uses host networking to bridge the loopback-only
`127.0.0.1:8384` API to `${SYNCTHING_RELAY_PORT}`. It does not remove
authentication: Syncthing still validates the `X-API-Key` header. Restrict that
port with the host firewall if the host is reachable by untrusted networks.

On the Mac, replace `<mac-host>` and `<mac-user>` in
`clients/alloy/syncthing.alloy`. Create
`/opt/homebrew/etc/grafana-alloy/syncthing-api-key` containing only the local
Mac Syncthing API key, with no trailing newline, and mode `0600`. The fragment
expects the existing `loki.write.carian` and `prometheus.remote_write.carian`
components from `00-outputs.alloy`.

The log tail assumes the standard macOS path
`~/Library/Application Support/Syncthing/syncthing.log`. Confirm that file is
being written on the Mac; if its launch method redirects logs elsewhere, update
the fragment's `__path__` before installing.

## Apply on the forge host

Run these steps only after reviewing the generated configuration:

```bash
cd /path/to/carian-observatory/services/monitoring
mkdir -p secrets
umask 077
api_key="$(sed -n 's:.*<apikey>\([^<]*\)</apikey>.*:\1:p' \
  "$HOME/.local/state/syncthing/config.xml")"
printf '%s' "$api_key" > secrets/syncthing-api-key
unset api_key

export SYNCTHING_API_KEY_FILE=./secrets/syncthing-api-key
export SYNCTHING_RELAY_PORT=18384
export SYNCTHING_FORGE_HOST_LABEL=<forge-host>
envsubst '${SYNCTHING_RELAY_PORT} ${SYNCTHING_FORGE_HOST_LABEL} ${GAMING_PC_NODE_PORT} ${GAMING_PC_GPU_PORT} ${GAMING_PC_INSTANCE_NAME} ${GAMING_PC_HOST_LABEL} ${GAMING_PC_LOCATION} ${GAMING_PC_OS} ${GAMING_PC_DISTRO} ${GAMING_PC_GPU_VENDOR} ${GAMING_PC_GPU_MODEL}' \
  < prometheus/prometheus.yml.template > prometheus/prometheus.yml
envsubst '${GAMING_PC_INSTANCE_NAME} ${GAMING_PC_DISPLAY_NAME} ${GAMING_PC_ALERT_PREFIX}' \
  < prometheus/alerts.yml.template > prometheus/alerts.yml

docker compose config
docker compose up -d syncthing-relay prometheus promtail grafana
```

`--web.enable-remote-write-receiver` is included so the Mac can push to the
existing `/prometheus/api/v1/write` endpoint on host port 9095. Promtail mounts
the persistent and runtime journal locations and keeps only
the `syncthing.service` or `syncthing@<user>.service` unit, labeling it with `host` and `unit`.

## Apply on the Mac

Copy the existing shared `00-outputs.alloy` and this repository's fragment into
one directory, or place the fragment alongside the already-installed shared
output. Ensure the output URLs retain the existing push-only endpoints:

```text
http://<forge-host>:3100/loki/api/v1/push
http://<forge-host>:9095/prometheus/api/v1/write
```

Then:

```zsh
cd /path/to/carian-observatory/clients/alloy
sed -i '' 's/<mac-host>/<desired-host-label>/g; s/<mac-user>/<local-user>/g' syncthing.alloy
mkdir -p /opt/homebrew/etc/grafana-alloy
umask 077
printf '%s' '<mac-syncthing-api-key>' > /opt/homebrew/etc/grafana-alloy/syncthing-api-key
./install-syncthing.sh
```

The installer formats the fragment and restarts only the Mac Alloy brew service.
For a direct reload instead, after copying the fragment and creating the secret:

```zsh
brew services restart grafana-alloy
```

## Alert semantics

- A scrape failure lasting two minutes is critical.
- A remote device with zero active connections for five minutes warns.
- Folder state `8` (`FolderError`) lasting two minutes is critical. Syncthing's
  Prometheus endpoint does not expose per-item pull errors separately; the
  associated log stream is the diagnostic source for pull errors.
- Any needed files, directories, symlinks, or deletions remaining for 15 minutes
  warns that a folder is out of sync. Change the rule's `for: 15m` to tune N.

The provisioned Syncthing dashboard is in the existing Carian Observatory
Grafana folder and includes completion, needed items/bytes, device connectivity,
folder errors, and logs.


## Relay exposure

The relay listens only on `SYNCTHING_RELAY_BIND` (default `172.17.0.1`, the docker bridge gateway that containers reach as `host.docker.internal`). It is therefore not reachable from the tailnet or LAN; Syncthing itself stays bound to 127.0.0.1 and still requires `X-API-Key`. If your docker0 gateway differs (`ip -4 addr show docker0`), set `SYNCTHING_RELAY_BIND` accordingly.
