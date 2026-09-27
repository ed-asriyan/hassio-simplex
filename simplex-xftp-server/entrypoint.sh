#!/bin/sh

# Options from HA config
ADDR=$(jq -r '.addr' /data/options.json)
PORT=$(jq -r '.port' /data/options.json)
QUOTA=$(jq -r '.quota' /data/options.json)
PASS=$(jq -r '.pass // ""' /data/options.json)
EXPIRE_FILES_HOURS=$(jq -r '.expire_files_hours' /data/options.json)
NEW_FILES=$(jq -r 'if .new_files then "on" else "off" end' /data/options.json)
SSL=$(jq -r '.ssl.enabled' /data/options.json)
CERTFILE=/ssl/$(jq -r '.ssl.certfile' /data/options.json)
KEYFILE=/ssl/$(jq -r '.ssl.keyfile' /data/options.json)

# How often to check whether the certificate was renewed, seconds
CERT_CHECK_INTERVAL=${CERT_CHECK_INTERVAL:-3600}

# Optional server information, one "key = value" line per non-empty field
INFORMATION=$(jq -r '(.information // {}) | to_entries[] | select(.value != null and .value != "") | "\(.key) = \(.value | tostring | gsub("[\r\n]"; " "))"' /data/options.json)

# Define directories
CONFIG_DIR=/etc/opt/simplex-xftp
STATE_DIR=/var/opt/simplex-xftp
FILES_DIR=/srv/xftp
INI=${CONFIG_DIR}/file-server.ini

# Symlink data directories so HA backs them up
mkdir -p /data/config /data/state /data/files
[ -L "$CONFIG_DIR" ] || { rm -rf "$CONFIG_DIR" && ln -s /data/config "$CONFIG_DIR"; }
[ -L "$STATE_DIR"  ] || { rm -rf "$STATE_DIR"  && ln -s /data/state  "$STATE_DIR";  }
[ -L "$FILES_DIR"  ] || { rm -rf "$FILES_DIR"  && ln -s /data/files  "$FILES_DIR";  }

# Initialize certificates on first run (generates TLS certs and fingerprint)
if [ ! -f "$INI" ]; then
    case "$ADDR" in
        *[a-zA-Z]*) xftp-server init --store-log --path "$FILES_DIR" --fqdn "$ADDR" --quota "$QUOTA" ;;
        *)          xftp-server init --store-log --path "$FILES_DIR" --ip   "$ADDR" --quota "$QUOTA" ;;
    esac
fi

# Use the certificate from /ssl (e.g. issued by the Let's Encrypt app) for HTTPS on the XFTP port
WEB_SECTION=""
if [ "$SSL" = "true" ]; then
    KEY_INFO=$(openssl x509 -in "$CERTFILE" -noout -text 2>/dev/null)
    if [ ! -r "$CERTFILE" ] || [ ! -r "$KEYFILE" ]; then
        echo "WARNING: ${CERTFILE} or ${KEYFILE} not found, HTTPS is disabled."
        echo "WARNING: Issue a certificate for ${ADDR} with the Let's Encrypt app or disable SSL."
    elif ! echo "$KEY_INFO" | grep -q -E "rsaEncryption|ASN1 OID: prime256v1"; then
        echo "WARNING: XFTP server supports only RSA or ECDSA P-256 certificates for HTTPS. HTTPS is disabled."
        echo "WARNING: In the Let's Encrypt app set 'key_type: rsa' or 'elliptic_curve: secp256r1', or disable SSL."
    else
        case "$ADDR" in
            *[a-zA-Z]*) CHECK="-checkhost" ;;
            *)          CHECK="-checkip"   ;;
        esac
        if ! openssl x509 -in "$CERTFILE" -noout "$CHECK" "$ADDR" | grep -q "does match"; then
            echo "WARNING: ${CERTFILE} is not issued for ${ADDR}, browsers will not trust the server page"
        fi
        WEB_SECTION=$(printf '[WEB]\nstatic_path = %s/www\ncert = %s\nkey = %s' "$STATE_DIR" "$CERTFILE" "$KEYFILE")
    fi
fi

# Render config from scratch on every start
if [ -n "$PASS" ]; then
    CREATE_PASSWORD_LINE="create_password = ${PASS}"
else
    CREATE_PASSWORD_LINE=""
fi
export ADDR PORT QUOTA EXPIRE_FILES_HOURS NEW_FILES FILES_DIR CREATE_PASSWORD_LINE WEB_SECTION INFORMATION
envsubst < /file-server.ini.tpl > "$INI"

# Print server address
FINGERPRINT=$(cat "${CONFIG_DIR}/fingerprint" 2>/dev/null || true)
if [ -n "$FINGERPRINT" ]; then
    echo "=========================================="
    echo "XFTP server address:"
    if [ -n "$PASS" ]; then
        echo "xftp://${FINGERPRINT}:${PASS}@${ADDR}:${PORT}"
    else
        echo "xftp://${FINGERPRINT}@${ADDR}:${PORT}"
    fi
    echo "=========================================="
fi

if [ "$SSL" != "true" ]; then
    exec xftp-server start +RTS -N -RTS
fi

cert_hash() {
    cat "$CERTFILE" "$KEYFILE" 2>/dev/null | sha256sum
}

# xftp-server reads the certificate only on start, so restart it when the certificate is renewed
watch_cert() {
    initial=$(cert_hash)
    while sleep "$CERT_CHECK_INTERVAL"; do
        if [ "$(cert_hash)" != "$initial" ]; then
            kill -HUP $$
            return
        fi
    done
}

RESTART=""
trap 'RESTART=1; kill -INT "$SERVER" 2>/dev/null' HUP
trap 'kill -INT "$SERVER" 2>/dev/null' INT TERM

xftp-server start +RTS -N -RTS &
SERVER=$!

watch_cert &
WATCHER=$!

# "wait" returns early when a trap fires, so wait until the server is really gone
wait "$SERVER"
RC=$?
while kill -0 "$SERVER" 2>/dev/null; do
    wait "$SERVER"
    RC=$?
done
kill "$WATCHER" 2>/dev/null

if [ -n "$RESTART" ]; then
    echo "Certificate ${CERTFILE} was changed, restarting XFTP server..."
    exec "$0"
fi
exit "$RC"
