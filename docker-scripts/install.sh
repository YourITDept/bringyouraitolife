#!/bin/bash
#
# File: docker-scripts/install.sh
# Version: 1.0.1
#

set -e

move_if_different() {
  local source_file="$1"
  local destination_dir="$2"
  local file_name
  local destination_file
  local backup_dir
  local timestamp
  local backup_file
  local normalized_file

  if [ -z "${source_file}" ] || [ -z "${destination_dir}" ]; then
    echo "[install] ERROR: usage: move_if_different <path/file> <destination_dir>"
    return 1
  fi

  if [ ! -f "${source_file}" ]; then
    echo "[install] ERROR: source file does not exist: ${source_file}"
    return 1
  fi

  mkdir -p "${destination_dir}"

  file_name="$(basename "${source_file}")"
  destination_file="${destination_dir}/${file_name}"
  backup_dir="${destination_dir}/Backup"

  if [ "${source_file##*.}" = "sh" ]; then
    if command -v dos2unix >/dev/null 2>&1; then
      dos2unix "${source_file}" >/dev/null 2>&1
    else
      normalized_file="$(mktemp)"
      tr -d '\r' < "${source_file}" > "${normalized_file}"
      mv "${normalized_file}" "${source_file}"
    fi
  fi

  if [ -f "${destination_file}" ] && cmp -s "${source_file}" "${destination_file}"; then
    echo "[install] Info: ${destination_file} is unchanged"
    return 0
  fi

  if [ -f "${destination_file}" ]; then
    mkdir -p "${backup_dir}"
    timestamp="$(date +%Y%m%d%H%M)"
    backup_file="${backup_dir}/${file_name}.${timestamp}"
    mv "${destination_file}" "${backup_file}"
    echo "[install] Info: backed up ${destination_file} to ${backup_file}"
  fi

  cp "${source_file}" "${destination_file}"

  if [ "${destination_file##*.}" = "sh" ]; then
    chmod 555 "${destination_file}"
  fi

  echo "[install] Info: copied ${source_file} to ${destination_file}"
}
echo "[install] Info: Docker Scipt Install stated"

echo "[install] Info: Docker Scipt Install completed"