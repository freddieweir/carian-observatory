#!/bin/zsh
# Installs/refreshes the Syncthing Alloy fragment. Re-run after edits.
set -euo pipefail

script_dir="${0:A:h}"
brew_prefix="$(brew --prefix)"
alloy_etc="$brew_prefix/etc/grafana-alloy"
secret_file="$alloy_etc/syncthing-api-key"

brew list --formula grafana-alloy >/dev/null 2>&1 || brew install grafana-alloy

mkdir -p "$alloy_etc"
cp "$script_dir/syncthing.alloy" "$alloy_etc/20-syncthing.alloy"

if [[ ! -s "$secret_file" ]]; then
  print -u2 "Missing $secret_file (write only the Syncthing API key, with no newline; chmod 600)."
  exit 1
fi

chmod 600 "$secret_file"
"$brew_prefix/bin/alloy" fmt "$alloy_etc/20-syncthing.alloy" > /dev/null
brew services restart grafana-alloy

print "Deployed 20-syncthing.alloy; Alloy UI: http://127.0.0.1:12345"
