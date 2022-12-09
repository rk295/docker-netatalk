#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

AFP_GID=${AFP_GID:-}
AFP_PASSWORD=${AFP_PASSWORD:-}
AFP_UID=${AFP_UID:-}
AFP_USER=${AFP_USER:-}
AVAHI=${AVAHI:-}

cmd=()

if [[ -n "${AFP_USER}" ]]; then
    
    if [[ -n "${AFP_UID}" ]]; then
        cmd+=("--uid")
        cmd+=("$AFP_UID")
    fi
    
    if [[ -n "${AFP_GID}" ]]; then
        cmd+=("--gid")
        cmd+=("$AFP_GID")
        groupadd --gid "${AFP_GID}" "${AFP_USER}" || true # Might already exist
    fi

    adduser "${cmd[@]}" --no-create-home --disabled-password --gecos '' "${AFP_USER}"

    if [[ -n "${AFP_PASSWORD}" ]]; then
        echo "${AFP_USER}:${AFP_PASSWORD}" | chpasswd
    fi
fi

if [[ ! -d /media/share ]]; then
  mkdir /media/share
fi
[[ -n "$AFP_USER" ]] && chown "$AFP_USER" /media/share

if [[ ! -d /media/timemachine ]]; then
  mkdir /media/timemachine
fi
[[ -n "$AFP_USER" ]] && chown "${AFP_USER}" /media/timemachine

[[ -n "$AFP_USER" ]] && sed -i'' -e "s,%USER%,${AFP_USER},g" /etc/afp.conf

echo ---begin-afp.conf--
cat /etc/afp.conf
echo ---end---afp.conf--

mkdir -p /var/run/dbus
rm -f /var/run/dbus/pid
dbus-daemon --system

if [[ "${AVAHI}" == "1" ]]; then
    sed -i '/rlimit-nproc/d' /etc/avahi/avahi-daemon.conf
    avahi-daemon -D
else
    echo "Skipping avahi daemon, enable with env variable AVAHI=1"
fi

exec netatalk -d
