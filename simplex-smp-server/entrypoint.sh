#!/bin/sh

# Options from HA config
ADDR=$(jq -r '.addr' /data/options.json)
PORT=$(jq -r '.port' /data/options.json)
PASS=$(jq -r '.pass // ""' /data/options.json)
NEW_QUEUES=$(jq -r 'if .new_queues then "on" else "off" end' /data/options.json)
RESTORE_MESSAGES=$(jq -r 'if .restore_messages then "on" else "off" end' /data/options.json)
EXPIRE_MESSAGES_DAYS=$(jq -r '.expire_messages_days' /data/options.json)
EXPIRE_NTFS_HOURS=$(jq -r '.expire_ntfs_hours' /data/options.json)

# Optional server information, one "key = value" line per non-empty field
INFORMATION=$(jq -r '(.information // {}) | to_entries[] | select(.value != null and .value != "") | "\(.key) = \(.value | tostring | gsub("[\r\n]"; " "))"' /data/options.json)

# Define directories
CONFIG_DIR=/etc/opt/simplex
STATE_DIR=/var/opt/simplex
INI=${CONFIG_DIR}/smp-server.ini

# Symlink data directories so HA backs them up
mkdir -p /data/config /data/state
[ -L "$CONFIG_DIR" ] || { rm -rf "$CONFIG_DIR" && ln -s /data/config "$CONFIG_DIR"; }
[ -L "$STATE_DIR"  ] || { rm -rf "$STATE_DIR"  && ln -s /data/state  "$STATE_DIR";  }

# Initialize certificates on first run (generates TLS certs and fingerprint)
if [ ! -f "$INI" ]; then
    smp-server init --yes
fi

# Render config from scratch on every start
if [ -n "$PASS" ]; then
    CREATE_PASSWORD_LINE="create_password: ${PASS}"
else
    CREATE_PASSWORD_LINE=""
fi
export ADDR PORT NEW_QUEUES RESTORE_MESSAGES EXPIRE_MESSAGES_DAYS EXPIRE_NTFS_HOURS CREATE_PASSWORD_LINE INFORMATION
envsubst < /smp-server.ini.tpl > "$INI"

# Print server address
FINGERPRINT=$(cat "${CONFIG_DIR}/fingerprint" 2>/dev/null || true)
if [ -n "$FINGERPRINT" ]; then
    echo "=========================================="
    echo "SMP server address:"
    if [ -n "$PASS" ]; then
        echo "smp://${FINGERPRINT}:${PASS}@${ADDR}:${PORT}"
    else
        echo "smp://${FINGERPRINT}@${ADDR}:${PORT}"
    fi
    echo "=========================================="
fi

exec smp-server start +RTS -N -RTS
