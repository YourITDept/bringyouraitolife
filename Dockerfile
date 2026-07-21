# Project: octobot 
# File: Dockerfile
#
# License: MIT License - THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND (see LICENSE file)
#
# GitHub: https://github.com/YourITDept/bringyouraitolife.git
#
# If you want to use Hostinger to start up your VPS Docker container 
#  then you can use the following code and get 20% off
#    https://www.hostinger.com?REFERRALCODE=TMLYCWAQCNC0
#

# Command line Docker examples for local build:
#   docker build --no-cache --platform linux/arm64 -t octobot-v61-arm64 .
#   docker build --no-cache --platform linux/amd64 -t octobot-v61-amd64 .

FROM ubuntu:24.04

ARG OCTOBOT_VERSION=v61
ENV OCTOBOT_VERSION=${OCTOBOT_VERSION}

ARG PAPERCLIP_SNAPSHOT=v2026.720.0
ENV PAPERCLIP_SNAPSHOT=${PAPERCLIP_SNAPSHOT}

ARG BOT_LOGIN=octobot
ENV BOT_LOGIN=${BOT_LOGIN}

ARG SSH_PORT=22
ENV SSH_PORT=${SSH_PORT}

ARG OPENCLAW_PORT=18789
ENV OPENCLAW_PORT=${OPENCLAW_PORT}

ARG PAPERCLIP_PORT=3100
ENV PAPERCLIP_PORT=${PAPERCLIP_PORT}

ARG HERMES_PORT_API=8642
ENV HERMES_PORT_API=${HERMES_PORT_API}
ARG HERMES_PORT_WEB=9119
ENV HERMES_PORT_WEB=${HERMES_PORT_WEB}

ARG PROXY_PORT=8080
ENV PROXY_PORT=${PROXY_PORT}

ENV DEBIAN_FRONTEND=noninteractive

USER root

RUN echo ${OCTOBOT_VERSION} > /etc/octobot-version

# Install Ubuntu System Packages to run container - git for Homebrew
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      build-essential procps lsb-release \
      openssh-server sudo \
      supervisor \
      net-tools iputils-ping dnsutils iproute2 socat \
      file vim expect \
      dos2unix \
      bubblewrap \
      jq curl git xdg-utils \
    && rm -rf /var/lib/apt/lists/* 

# Setup SSHD to run and listen on all networks for external connections
RUN mkdir -p /run/sshd && \
    sed -i "s/^#\\?Port .*/Port ${SSH_PORT}/" /etc/ssh/sshd_config && \
    sed -i 's/#ListenAddress 0.0.0.0/ListenAddress 0.0.0.0/' /etc/ssh/sshd_config && \
    dos2unix /etc/ssh/sshd_config && \
    useradd \
      --create-home \
      --shell /bin/bash \
      --groups sudo \
        ${BOT_LOGIN} && \
    echo "${BOT_LOGIN} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    passwd -l ${BOT_LOGIN}

#==============================================================================   
# Install Homebrew as ${BOT_LOGIN}
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++  
USER ${BOT_LOGIN}
ENV NONINTERACTIVE=true
ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"
RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" && \
    /home/linuxbrew/.linuxbrew/bin/brew -v && \
    mkdir -p /home/${BOT_LOGIN}/bin && \
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/${BOT_LOGIN}/.bashrc && \
    echo '[ -f /etc/profile.d/container-env.sh ] && source /etc/profile.d/container-env.sh' >> /home/${BOT_LOGIN}/.bashrc: && \
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/${BOT_LOGIN}/.profile && \
    echo '[ -f /etc/profile.d/container-env.sh ] && source /etc/profile.d/container-env.sh' >> /home/${BOT_LOGIN}/.profile && \
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/${BOT_LOGIN}/setenv.pr && \
    echo '[ -f /etc/profile.d/container-env.sh ] && source /etc/profile.d/container-env.sh' >> /home/${BOT_LOGIN}/setenv.pr && \
    type brew && \
    brew -v && \
    brew update && \
    brew install \
          git curl wget less \
          gcc make \
          gnu-tar \
          node@22 pnpm \
          python pyenv uv pipx \
          ffmpeg ripgrep \
          screen tmux \
          libpq && \
    echo 'export PATH=$PATH:$(brew --prefix libpq)/bin' > /home/${BOT_LOGIN}/setenv.pr

#==============================================================================\
# OpenAI Codex
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++|
USER ${BOT_LOGIN}
RUN brew install codex && \
   mkdir -p /home/${BOT_LOGIN}/Codex 
# RUN sudo ln -sf /home/linuxbrew/.linuxbrew/bin/bwrap /usr/bin/bwrap # Move install to apt
#------------------------------------------------------------------------------

#==============================================================================
# Hermes Agent
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Hermes
USER ${BOT_LOGIN}
RUN brew install hermes-agent && \
    mkdir -p /home/${BOT_LOGIN}/Hermes && \
    cat > /home/${BOT_LOGIN}/bin/hermes-dashboard.sh <<'EOF'
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

exec hermes dashboard --host 0.0.0.0 --port "$HERMES_PORT_WEB" --no-open
EOF
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
RUN dos2unix /home/${BOT_LOGIN}/bin/hermes-dashboard.sh && \
    chmod +x /home/${BOT_LOGIN}/bin/hermes-dashboard.sh
#------------------------------------------------------------------------------

#==============================================================================
# Write expect script to run claude remote-control with a PTY
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
USER ${BOT_LOGIN}

# Claude Code
#RUN npm install -g @anthropic-ai/claude-code
RUN brew install --cask claude-code && \
    mkdir -p /home/${BOT_LOGIN}/ClaudeCode && \
    cat > /home/${BOT_LOGIN}/bin/claude-remote.exp <<'EOF'
#!/usr/bin/expect -f

log_user 1
set timeout -1

if {![file exists "AUTORUN.md"]} {
    puts {[claude-remote.exp] Claude Code Login setup required then create AUTORUN.md}
    exit 0
}

spawn /bin/bash -c "source ~/.bashrc && claude remote-control"

expect {
    -re "Enable Remote Control" {
        puts -nonewline $expect_out(buffer)
        flush stdout
        after 2000
        send "y\r"
        exp_continue
    }
    eof {
        exit 1
    }
}
EOF
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
RUN dos2unix /home/${BOT_LOGIN}/bin/claude-remote.exp && \
    chmod +x /home/${BOT_LOGIN}/bin/claude-remote.exp && \
    mkdir -p /home/${BOT_LOGIN}/ClaudeCode
#------------------------------------------------------------------------------

#==============================================================================\
# Script to start Openclaw
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++|
USER ${BOT_LOGIN}
RUN mkdir -p /home/${BOT_LOGIN}/Openclaw && \
    cat > /home/${BOT_LOGIN}/bin/openclaw-gw.sh  <<'EOF'
#!/bin/bash

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
EOF
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++|
RUN dos2unix /home/${BOT_LOGIN}/bin/openclaw-gw.sh && \
    chmod +x /home/${BOT_LOGIN}/bin/openclaw-gw.sh && \
    mkdir -p /home/${BOT_LOGIN}/Openclaw
#------------------------------------------------------------------------------/

#==============================================================================\
# Script to Obsidian Sync
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++|
USER ${BOT_LOGIN}
# RUN npm install -g obsidian-headless # Need to fix as of v31b
RUN mkdir -p /home/${BOT_LOGIN}/Obsidian && \
    cat > /home/${BOT_LOGIN}/bin/obsidian-sync.sh  <<'EOF'
#!/bin/bash
# Tested with Claude Code 2.1.87 and Obsidian ob 0.0.8
#     claude -v && ob --version

if [ ! -f "$HOME/Obsidian/AUTORUN.md" ]; then
  echo "[obsidian-sync.sh] AUTORUN.md file does not exist - create it to auto run the process"
  exit 0
fi

source "$HOME/.bashrc"

# Create the Obsidian Vault Directories if they do not exist
HOSTNAME="$(hostname)"
HOST_OBSIDIAN_DIR="$HOME/Obsidian/${HOSTNAME}"
if [ ! -d "${HOST_OBSIDIAN_DIR}" ]; then
    mkdir -p "${HOST_OBSIDIAN_DIR}"
fi

for DIR_NAME in Openclaw-Workspace ClaudeCode Codex Paperclip Hermes; do
    if [ -d "$HOME/${DIR_NAME}" ] && [ ! -e "${HOST_OBSIDIAN_DIR}/${DIR_NAME}" ]; then
            ln -s "$HOME/${DIR_NAME}" "${HOST_OBSIDIAN_DIR}/${DIR_NAME}"
    fi
done

# Pick up the projects in the .claude area for reference
if [ -d "$HOME/.claude/projects" ] && [ ! -e "${HOST_OBSIDIAN_DIR}/ClaudeCode/projects" ]; then
    ln -s "$HOME/.claude/projects" "${HOST_OBSIDIAN_DIR}/ClaudeCode/projects"
fi

# Pick up the workspace in the .Openclaw area for reference
if [ -d "$HOME/.openclaw/workspace" ]; then
  if [ ! -e "${HOST_OBSIDIAN_DIR}/Openclaw/workspace" ]; then
    ln -s "$HOME/.openclaw/workspace" "${HOST_OBSIDIAN_DIR}/Openclaw/workspace"
  fi
fi

cd "$HOME/Obsidian"

# Please SourceCode so not included in the Obsidian Vault and not synced to the OS,
#  but still have it in the container for the bots to use.
ob sync-config \
  --excluded-folders "$(hostname)/ClaudeCode/SourceCode,$(hostname)/Codex/SourceCode,$(hostname)/Openclaw/SourceCode"

ob sync && \
  ob sync --continuous
EOF
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++|
RUN dos2unix /home/${BOT_LOGIN}/bin/obsidian-sync.sh && \
    chmod +x /home/${BOT_LOGIN}/bin/obsidian-sync.sh && \
    mkdir -p /home/${BOT_LOGIN}/Obsidian
#------------------------------------------------------------------------------/

#==============================================================================\
# Script to start Paperclip
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++|
USER ${BOT_LOGIN}
# Download and build Paperclip
RUN git clone -b ${PAPERCLIP_SNAPSHOT} --single-branch https://github.com/YourITDept/paperclip.git ${HOME}/Paperclip && \
    echo "${PAPERCLIP_SNAPSHOT}" > ${HOME}/Paperclip/SNAPSHOTVERSION.md && \
    cat > ${HOME}/bin/paperclip-run.sh  <<'EOF'
#!/bin/bash
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
EOF
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++|
RUN dos2unix /home/${BOT_LOGIN}/bin/paperclip-run.sh && \
    chmod +x /home/${BOT_LOGIN}/bin/paperclip-run.sh
#------------------------------------------------------------------------------/

#==============================================================================\
# Create supervisord.conf
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++|
USER root
RUN mkdir -p /var/log/supervisor /etc/supervisor/conf.d
RUN cat > /etc/supervisor/conf.d/supervisord.conf <<EOF
[supervisord]
nodaemon=true
user=root
logfile=/dev/stdout
logfile_maxbytes=0
pidfile=/home/${BOT_LOGIN}/supervisord.pid

[program:sshd]
user=root
directory=/
command=/usr/sbin/sshd -D -e
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
redirect_stderr=true
startretries=9999
stopwaitsecs=15
autostart=true
autorestart=true

[program:openclaw-gw]
user=${BOT_LOGIN}
environment=USER="${BOT_LOGIN}",HOME="/home/${BOT_LOGIN}",TERM="xterm"
directory=/home/${BOT_LOGIN}/Openclaw
command=/bin/bash --login -c "/home/${BOT_LOGIN}/bin/openclaw-gw.sh"
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
startsecs=15
startretries=9999
stopwaitsecs=15
autostart=true
autorestart=true
exitcodes=0,1

[program:claude-remote]
user=${BOT_LOGIN}
environment=USER="${BOT_LOGIN}",HOME="/home/${BOT_LOGIN}",TERM="xterm"
directory=/home/${BOT_LOGIN}/ClaudeCode
command=/bin/bash --login -c "/home/${BOT_LOGIN}/bin/claude-remote.exp"
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
startsecs=15
startretries=9999
stopwaitsecs=15
autostart=true
autorestart=true
exitcodes=0,1

[program:paperclip]
user=${BOT_LOGIN}
environment=USER="${BOT_LOGIN}",HOME="/home/${BOT_LOGIN}",TERM="xterm"
directory=/home/${BOT_LOGIN}/Paperclip
command=/bin/bash --login -c "/home/${BOT_LOGIN}/bin/paperclip-run.sh"
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
startsecs=15
startretries=9999
stopwaitsecs=15
autostart=true
autorestart=true

[program:hermes-dashboard]
user=${BOT_LOGIN}
environment=USER="${BOT_LOGIN}",HOME="/home/${BOT_LOGIN}",TERM="xterm"
directory=/home/${BOT_LOGIN}/Hermes
command=/bin/bash --login -c "/home/${BOT_LOGIN}/bin/hermes-dashboard.sh"
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
startsecs=15
startretries=9999
stopwaitsecs=15
autostart=true
autorestart=true
exitcodes=0,1

[program:obsidian-sync]
user=${BOT_LOGIN}
environment=USER="${BOT_LOGIN}",HOME="/home/${BOT_LOGIN}",TERM="xterm"
directory=/home/${BOT_LOGIN}/Obsidian
command=/bin/bash --login -c "/home/${BOT_LOGIN}/bin/obsidian-sync.sh"
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
startsecs=15
startretries=9999
stopwaitsecs=15
autostart=true
autorestart=true
exitcodes=0,1
EOF
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++|
RUN dos2unix /etc/supervisor/conf.d/supervisord.conf
#------------------------------------------------------------------------------/

#==============================================================================\
# Create entrypoint script to set password at runtime - entrypoint.sh
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++|
USER root
RUN cat > /entrypoint.sh <<'EOF'
#!/bin/bash
set -e

if [ -z "${BOT_LOGIN}" ]; then
    echo "[entrypoint] ERROR: BOT_LOGIN is not set, cannot continue"
    exit 1
fi

cat > /etc/profile.d/container-env.sh <<EOF2
export OCTOBOT_VERSION="$(cat /etc/octobot-version 2>/dev/null || echo 'unknown')"
export BOT_LOGIN="${BOT_LOGIN}"
export BOT_NAME="$(hostname)"
export SSH_PORT="${SSH_PORT}"
export OPENCLAW_PORT="${OPENCLAW_PORT}"
export PAPERCLIP_SNAPSHOT="${PAPERCLIP_SNAPSHOT}"
export PAPERCLIP_PORT="${PAPERCLIP_PORT}"
#export HERMES_DASHBOARD_BASIC_AUTH_USERNAME="${HERMES_LOGIN}"
#export HERMES_DASHBOARD_BASIC_AUTH_PASSWORD="${HERMES_PASSWORD}"
#export HERMES_INSTALL="/home/${BOT_LOGIN}/Hermes"
EOF2

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

EOF
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++|
RUN dos2unix /entrypoint.sh && chmod +x /entrypoint.sh
#------------------------------------------------------------------------------/

# Lock down the container with sudoer as it was used to insall Homebrew above with out password prompt
RUN sed -i "s/^${BOT_LOGIN} ALL=(ALL) NOPASSWD:ALL$/${BOT_LOGIN} ALL=(ALL) ALL/" /etc/sudoers && \
    echo "Defaults:${BOT_LOGIN} timestamp_timeout=0" >> /etc/sudoers

# Expose SSH and OpenClaw GUI ports
EXPOSE ${SSH_PORT}
EXPOSE ${OPENCLAW_PORT}
EXPOSE ${PAPERCLIP_PORT}
EXPOSE ${HERMES_PORT_API}
EXPOSE ${HERMES_PORT_WEB}
EXPOSE ${PROXY_PORT}

ENTRYPOINT ["/entrypoint.sh"]
