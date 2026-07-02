#!/bin/bash
#
# File: docker-scripts/entrypoint.sh
# Version: 1.0.1
#

set -e

if [ -z "${BOT_LOGIN}" ]; then
    echo "[entrypoint] ERROR: BOT_LOGIN is not set, cannot continue"
    exit 1
fi

if [ "${LIVE_UPDATE}" = true ]; then
  echo "[entrypoint] live_update is set, running live update commands"

  if [ -d /bringyouraitolife ]; then
    cd /bringyouraitolife
    git pull
  else
    git checkout https://github.com/YourITDept/bringyouraitolife /bringyouraitolife
  fi

  # Run the install script to move around the files
  if [ -f /bringyouraitolife/docker-scripts/install.sh ]; then
    /bringyouraitolife/docker-scripts/install.sh
  fi
  
  export LIVE_UPDATE=false

  # Start the Docker conatiner out the live update
  if [ -f /bringyouraitolife/docker-scripts/entrypoint.sh ]; then
    /bringyouraitolife/docker-scripts/entrypoint.sh
    echo "[entrypoint] update entrypoint script completed"
    exit 0
  fi
fi

#===================================================================
cat > /etc/profile.d/container-env.sh <<EOF2
export OCTOBOT_VERSION="$(cat /etc/octobot-version 2>/dev/null || echo 'unknown')"
export BOT_LOGIN="${BOT_LOGIN}"
export BOT_NAME="$(hostname)"
export SSH_PORT="${SSH_PORT}"
export OPENCLAW_PORT="${OPENCLAW_PORT}"
export PAPERCLIP_PORT="${PAPERCLIP_PORT}"
export HERMES_DASHBOARD_BASIC_AUTH_USERNAME="hermes"
export HERMES_DASHBOARD_BASIC_AUTH_PASSWORD="${BOT_PASSWORD}"
export HERMES_HOME="/home/${BOT_LOGIN}/Hermes"
EOF2
#===================================================================

chmod 644 /etc/profile.d/container-env.sh

FLAG_FILE="/home/${BOT_LOGIN}/.password_set"
if [ ! -f "${FLAG_FILE}" ] && [ -n "${BOT_PASSWORD}" ]; then
    echo "${BOT_LOGIN}:${BOT_PASSWORD}" | chpasswd
    echo "[entrypoint] Password set for user: ${BOT_LOGIN}"
    touch "${FLAG_FILE}"
fi

if passwd -S "$BOT_LOGIN" 2>/dev/null | grep -q ' L '; then
    echo "[entrypoint] WARNING: BOT_PASSWORD not set, SSH password login will not work"
    echo "[entrypoint] Info: $BOT_LOGIN account is locked."
    echo "[entrypoint]   Set password with passwd command"
else
    echo "[entrypoint] Info: $BOT_LOGIN account is unlocked"
fi

DIR=/home/${BOT_LOGIN}/.ssh
if [ ! -d "${DIR}" ]; then
  mkdir ${DIR}
  chmod 700 ${DIR}
fi
# For now will overwrite
if [ -n "${BOT_SSH_KEY}" ]; then
  echo "${BOT_SSH_KEY}" > ${DIR}/authorized_keys
  chmod 400 ${DIR}/authorized_keys
  chown ${BOT_LOGIN}:${BOT_LOGIN} ${DIR} ${DIR}/authorized_keys
  echo "[entrypoint] Info: Setup the SSH key for user ${BOT_LOGIN}"
fi

if [ -d /${BOT_LOGIN} ] && [ ! -d /${BOT_LOGIN}/Paperclip ] && [ -d /home/${BOT_LOGIN} ]; then
  cd /home && tar cf - -C ${BOT_LOGIN} . | (cd /${BOT_LOGIN} && tar xf -)
  echo "[entrypoint] Info: Copied files from /home/${BOT_LOGIN} to /${BOT_LOGIN} for persistence"
fi
if [ ! -L /home/${BOT_LOGIN} ] && [ ! -d /home/${BOT_LOGIN}- ] && [ -d /home/${BOT_LOGIN} ]; then
  mv /home/${BOT_LOGIN} /home/${BOT_LOGIN}- && \
  chown -R ${BOT_LOGIN}:${BOT_LOGIN} /${BOT_LOGIN} && \
  ln -s /${BOT_LOGIN} /home/${BOT_LOGIN} && \
  chown -h ${BOT_LOGIN}:${BOT_LOGIN} /home/${BOT_LOGIN}
  echo "[entrypoint] Info: Linked /home/${BOT_LOGIN} to /${BOT_LOGIN} for persistence"
fi

/usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf || exec bash