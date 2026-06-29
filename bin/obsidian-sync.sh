#!/bin/bash
#
# File: bin/obsidian-sync.sh
# Version: 1.0.1
#

[ -r "$HOME/.bashrc" ] && source "$HOME/.bashrc"

usage() {
  cat <<EOF
Usage: $(basename "$0") [-f|-force] [-s|-setup] [-p|-pull] [-a|-auto] [-h|-help|--help]

Options:
  -f, -force          Force run, skipping the AUTORUN check
  -s, -setup          Setup run
  -p, -pull           Pull latest changes before running bidirectional sync
  -a, -auto           Create the AUTORUN file to prepare for running automatically on restart 
  -h, -help, --help   Show this help message
EOF
}

SCRIPT="$(basename "$0")"
HOSTNAME="$(hostname)"
OBSIDIAN_DIR="${HOME}/Obsidian"
HOST_OBSIDIAN_DIR="${OBSIDIAN_DIR}/Agents/${HOSTNAME}"
FORCE_RUN=false
SETUP_RUN=false
PULL_RUN=false
AUTO_RUN=false

for arg in "$@"; do
  case "${arg}" in
    -h|-help|--help)
      usage
      exit 0
      ;;
    -f|-force)
      FORCE_RUN=true
      ;;
    -s|-setup)
      SETUP_RUN=true
      ;;
    -p|-pull)
      PULL_RUN=true
      ;;
    -a|-auto)
      AUTO_RUN=true
      ;;
    -*)
      echo "[${SCRIPT}] Unknown option: ${arg}" >&2
      exit 2
      ;;
  esac
done

if [ ! -d "${OBSIDIAN_DIR}/.obsidian" ]; then
   echo "[${SCRIPT}] Need to setup Obsidian first and sync once setup is complete"
   exit 0
fi

if [ ${SETUP_RUN} = true ]; then
  echo "[${SCRIPT}] Running setup for ${HOST_OBSIDIAN_DIR}"
  
  mkdir -p "${HOST_OBSIDIAN_DIR}"

  # Create symlinks for the agent directories in the Obsidian Vault if they do not exist
  # Need to figure out how want to setup Paperclip home foled. So skip for now.
  for DIR_NAME in .openclaw Openclaw .claude ClaudeCode .codex Codex .paperclip .hermes Hermes; do  
    if [ -d "${HOME}/${DIR_NAME}" ]; then
      echo "[${SCRIPT}] Found directory ${DIR_NAME} in home directory"
      
      [[ "${DIR_NAME}" == .* ]] && IS_DOT_FILE=true || IS_DOT_FILE=false

      if [ "${IS_DOT_FILE}" = true ]; then
        DIR_NAME_NO_DOT="${DIR_NAME#.}"
        if [ ! -d "${HOST_OBSIDIAN_DIR}/DOT-${DIR_NAME_NO_DOT}" ]; then
            echo "[${SCRIPT}] Creating symlink for ${DIR_NAME} to DOT-${DIR_NAME_NO_DOT} in Obsidian Vault"
            ln -s "${HOME}/${DIR_NAME}" "${HOST_OBSIDIAN_DIR}/DOT-${DIR_NAME_NO_DOT}"
        else
          echo "[${SCRIPT}] Symlink for DOT-${DIR_NAME_NO_DOT} already exists in Obsidian Vault"
        fi
      else        
        if [ ! -d "${HOST_OBSIDIAN_DIR}/${DIR_NAME}" ]; then
          echo "[${SCRIPT}] Creating symlink for ${DIR_NAME} in Obsidian Vault"
          ln -s "${HOME}/${DIR_NAME}" "${HOST_OBSIDIAN_DIR}/${DIR_NAME}"
        else
          echo "[${SCRIPT}] Symlink for ${DIR_NAME} already exists in Obsidian Vault"
        fi   
      fi
    fi
  done

  echo "[${SCRIPT}] Setup run completed"
  exit 0
fi

# Create the Obsidian Vault Directories if they do not exist
if [ ! -d "${HOST_OBSIDIAN_DIR}" ]; then
    echo "[${SCRIPT}] Need to setup directory for ${HOST_OBSIDIAN_DIR} first"
   exit 0
fi

if [ "${AUTO_RUN}" = true ]; then
  date >> "${HOST_OBSIDIAN_DIR}/AUTORUN"
  echo "[${SCRIPT}] Created ${HOST_OBSIDIAN_DIR}/AUTORUN"
  echo "\n[${SCRIPT}] Create AUTORUN file: `date`" >> ${HOST_OBSIDIAN_DIR}/RUNLOG.md
  exit 0
fi

# Look for the Auto Run file and then start syncing
if [ "${FORCE_RUN}" != true ] && [ "${PULL_RUN}" != true ] && [ ! -f "${HOST_OBSIDIAN_DIR}/AUTORUN" ]; then
  echo "[${SCRIPT}] AUTORUN file does not exist - create it to auto run the process"
  exit 0
fi

if [ "${PULL_RUN}" = true ]; then
  echo "\n[${SCRIPT}] Pull running Sync: `date`" >> ${HOST_OBSIDIAN_DIR}/RUNLOG.md
elif [ "${FORCE_RUN}" != true ]; then
  echo "\n[${SCRIPT}] Auto starting Sync: `date`" >> ${HOST_OBSIDIAN_DIR}/RUNLOG.md
else
  echo "\n[${SCRIPT}] Force running Sync: `date`" >> ${HOST_OBSIDIAN_DIR}/RUNLOG.md
fi  

cd "${OBSIDIAN_DIR}" || {
  echo "[${SCRIPT}] Failed to change directory into ${OBSIDIAN_DIR}" >&2
  exit 1
}

if [ "${PULL_RUN}" = true ]; then
  ob sync-config --mode pull-only && \
      ob sync && \
        ob sync-config --mode bidirectional
elif [ "${FORCE_RUN}" != true ]; then
  ob sync && \
    ob sync --continuous
else
    ob sync
fi
