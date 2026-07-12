#!/bin/bash
#
# File: bin/obsidian-brain-sync.sh
# Version: 1.0.1
#
# License: MIT License - THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND

[ -r "$HOME/.bashrc" ] && source "$HOME/.bashrc"

usage() {
  cat <<EOF
Usage: $(basename "$0") [-f|-force] [-s|-setup] [-p|-pull] [-D|-debug] [-obsidian-email EMAIL] [-obsidian-password PASSWORD] [-obsidian-syncpassword PASSWORD] [-obsidian-vault VAULT] [-h|-help|--help]

Options:
  -f, -force          Force run, skipping the AUTORUN check
  -s, -setup          Setup run
  -p, -pull           Pull latest changes before running bidirectional sync
  -D, -debug          Enable shell debug tracing
  -obsidian-email     Obsidian account email
  -obsidian-password  Obsidian account password
  -obsidian-syncpassword  Obsidian sync password
  -obsidian-vault     Obsidian vault name
  -h, -help, --help   Show this help message
EOF
}

SCRIPT="$(basename "$0")"

OBSIDIAN_DIR="${HOME}/BusinessBrain"
FORCE_RUN=false
SETUP_RUN=false
PULL_RUN=false
DEBUG_RUN=false
OBSIDIAN_EMAIL="${OBSIDIAN_EMAIL:-}"
OBSIDIAN_PASSWORD="${OBSIDIAN_PASSWORD:-}"
OBSIDIAN_SYNCPASSWORD="${OBSIDIAN_SYNCPASSWORD:-}"
OBSIDIAN_VAULT="${OBSIDIAN_VAULT:-}"

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|-help|--help)
      usage
      exit 0
      ;;
    -f|-force)
      FORCE_RUN=true
      shift
      ;;
    -s|-setup)
      SETUP_RUN=true
      shift
      ;;
    -p|-pull)
      PULL_RUN=true
      shift
      ;;
    -D|-debug)
      DEBUG_RUN=true
      shift
      ;;
    -obsidian-email)
      if [ -z "${2:-}" ]; then
        echo "[${SCRIPT}] Missing value for $1" >&2
        exit 2
      fi
      OBSIDIAN_EMAIL="$2"; SETUP_RUN=true
      shift 2
      ;;
    -obsidian-password)
      if [ -z "${2:-}" ]; then
        echo "[${SCRIPT}] Missing value for $1" >&2
        exit 2
      fi
      OBSIDIAN_PASSWORD="$2"; SETUP_RUN=true
      shift 2
      ;;
    -obsidian-syncpassword)
      if [ -z "${2:-}" ]; then
        echo "[${SCRIPT}] Missing value for $1" >&2
        exit 2
      fi
      OBSIDIAN_SYNCPASSWORD="$2"; SETUP_RUN=true
      shift 2
      ;;
    -obsidian-vault)
      if [ -z "${2:-}" ]; then
        echo "[${SCRIPT}] Missing value for $1" >&2
        exit 2
      fi
      OBSIDIAN_VAULT="$2"; SETUP_RUN=true
      shift 2
      ;;
    -*)
      echo "[${SCRIPT}] Unknown option: $1" >&2
      exit 2
      ;;
    *)
      echo "[${SCRIPT}] Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

if [ "${DEBUG_RUN}" = true ]; then
  set -x
fi

cd "${OBSIDIAN_DIR}" || {
  echo "[${SCRIPT}] Failed to change directory into ${OBSIDIAN_DIR}" >&2
  exit 1
}

if [ "${SETUP_RUN}" = true ]; then
  if [ -d "${OBSIDIAN_DIR}/.obsidian" ]; then
    echo "[${SCRIPT}] Looks like Obsidian was already setup in ${OBSIDIAN_DIR}" >&2
    exit 1
  fi
  if [ ! -d "${HOME}/.config/obsidian-headless" ]; then
    if [ -z "${OBSIDIAN_EMAIL}" ] || [ -z "${OBSIDIAN_PASSWORD}" ]; then
      echo "[${SCRIPT}] Obsidian email and password are needed to be set" >&2
      exit 1
    fi
  fi
  if [ ! -z "${OBSIDIAN_EMAIL}" ] && [ ! -z "${OBSIDIAN_PASSWORD}" ]; then
    ob login --email "${OBSIDIAN_EMAIL}" --password "${OBSIDIAN_PASSWORD}" || {
      echo "[${SCRIPT}] Failed to login to Obsidian for ${OBSIDIAN_EMAIL}" >&2
      exit 1
    }
  fi

  ob sync-list-remote || {
    echo "[${SCRIPT}] Failed to connect to Obsidian" >&2
    exit 1
  }

  if [ -z "${OBSIDIAN_SYNCPASSWORD}" ]; then
    ob sync-setup --vault "${OBSIDIAN_VAULT}" || {
      echo "[${SCRIPT}] Failed to setup Obsidian sync for ${OBSIDIAN_VAULT}" >&2
      exit 1
    }
  else 
    ob sync-setup --vault "${OBSIDIAN_VAULT}" --password "${OBSIDIAN_SYNCPASSWORD}" || {
      echo "[${SCRIPT}] Failed to setup Obsidian sync for ${OBSIDIAN_VAULT}" >&2
      exit 1
    }
  fi

  ob sync || {
    echo "[${SCRIPT}] Failed to sync the Obsidian vault ${OBSIDIAN_VAULT}" >&2
    exit 1
  }
fi

if [ ! -d "${OBSIDIAN_DIR}/.obsidian" ]; then
   echo "[${SCRIPT}] Need to setup Obsidian first and sync once in ${OBSIDIAN_DIR}"
   exit 0
fi

# Look for the Auto Run file and then start syncing
if [ "${FORCE_RUN}" != true ] && [ "${PULL_RUN}" != true ] && [ ! -f "${OBSIDIAN_DIR}/AUTORUN" ]; then
  echo "[${SCRIPT}] AUTORUN file does not exist - create it to auto run the process"
  exit 0
fi
   
if [ "${PULL_RUN}" = true ]; then
  ob sync-config --mode pull-only && \
    ob sync-config --mode bidirectional && \
      ob sync
elif [ "${FORCE_RUN}" != true ]; then
  ob sync && \
    ob sync --continuous
else
  ob sync
fi