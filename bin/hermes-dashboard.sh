#!/bin/bash
#
# File: bin/hermes-dashboard.sh
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
octobot@abcoctobot88:~/bin$ ls
claude-remote.exp  hermes-dashboard.sh  obsidian-sync.sh  openclaw-gw.sh  paperclip-run.sh
octobot@abcoctobot88:~/bin$ cat her*
#!/bin/bash
set -e

if [ ! -f "$HOME/Hermes/AUTORUN.md" ]; then
  echo "[hermes-dashboard.sh] AUTORUN.md file does not exist - create it to continue"
  exit 0
fi

source "$HOME/.bashrc"

if [ -z "${HERMES_PORT_WEB}" ]; then
  HERMES_PORT_WEB=9119
  export HERMES_PORT_WEB
  echo "[hermes-dashboard.sh] HERMES_PORT_WEB not set, defaulting to ${HERMES_PORT_WEB}"
fi

export HERMES_HOME="${HERMES_HOME:-$HOME/Hermes}"

echo "[hermes-dashboard.sh] Starting Hermes dashboard on port ${HERMES_PORT_WEB}..."
cd "$HERMES_HOME"

exec hermes dashboard --host 0.0.0.0 --port "$HERMES_PORT_WEB" --no-open1G