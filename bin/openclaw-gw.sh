#!/bin/bash
#
# File: bin/openclaw-gw.sh
# Version: 0.0.1
#

if [ ! -f "$HOME/Openclaw/AUTORUN.md" ]; then
  echo "[openclaw-gw.sh] AUTORUN.md file does not exist - create it to auto run the process"
  exit 0
fi

cd "$HOME/Openclaw"
source "$HOME/.bashrc"

#eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)"
#source "$HOME/.openclaw/completions/openclaw.bash"

if [ -z "${OPENCLAW_PORT}" ]; then
  OPENCLAW_PORT=18789
  export OPENCLAW_PORT
  echo "[openclaw-gw.sh] OPENCLAW_PORT not set, defaulting to ${OPENCLAW_PORT}"
fi

echo "[openclaw-gw.sh] Starting openclaw gateway..."

exec openclaw gateway run --port "$OPENCLAW_PORT" --verbose