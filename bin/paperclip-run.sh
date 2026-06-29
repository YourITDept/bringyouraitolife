#!/bin/bash
#
# File: bin/obsidian-brain-sync.sh
# Version: 0.0.1
#

set -e

source "$HOME/.bashrc"

if [ -z "${PAPERCLIP_PORT}" ]; then
  PAPERCLIP_PORT=3100
  export PAPERCLIP_PORT
  echo "[paperclip-run.sh] PAPERCLIP_PORT not set, defaulting to ${PAPERCLIP_PORT}"
fi
export PORT="${PAPERCLIP_PORT}"
export SERVE_UI="${SERVE_UI:-true}"

PAPERCLIP_DIR="$HOME/Paperclip"
PAPERCLIP_CONFIG="$HOME/.paperclip/instances/default/config.json"

if [ ! -d "${PAPERCLIP_DIR}" ]; then
  echo "[paperclip-run.sh] ERROR: ${PAPERCLIP_DIR} does not exist"
  exit 1
fi

if [ ! -f "${PAPERCLIP_DIR}/AUTORUN.md" ]; then
  echo "[paperclip-run.sh] AUTORUN.md file does not exist - create it to auto run the process"
  exit 0
fi

cd "${PAPERCLIP_DIR}"

# TODO: Add code to auto start
#if [ ! -f "${PAPERCLIP_CONFIG}" ]; then
#  echo "[paperclip-run.sh] Running first-time Paperclip onboarding..."
#  pnpm paperclipai onboard --yes --bind lan
#
#
# add_allowed_hostname "localhost"
# add_allowed_hostname "localhost:${PAPERCLIP_PORT}"
# add_allowed_hostname "127.0.0.1"
# add_allowed_hostname "127.0.0.1:${PAPERCLIP_PORT}"
# add_allowed_hostname "${PAPERCLIP_PUBLIC_URL}"
# add_allowed_hostname "${BETTER_AUTH_BASE_URL}"

echo "[paperclip-run.sh] Starting Paperclip on port ${PAPERCLIP_PORT}..."
exec pnpm paperclipai run