#!/usr/bin/env bash

# exit from script if error was raised.
set -e

# error function is used within a bash function in order to send the error
# message directly to the stderr output and exit.
error() {
    echo "$1" > /dev/stderr
    exit 0
}

# return is used within bash function in order to return the value.
return() {
    echo "$1"
}

# set_default function gives the ability to move the setting of default
# env variable from docker file to the script thereby giving the ability to the
# user override it durin container start.
set_default() {
    # docker initialized env variables with blank string and we can't just
    # use -z flag as usually.
    BLANK_STRING='""'

    VARIABLE="$1"
    DEFAULT="$2"

    if [[ -z "$VARIABLE" || "$VARIABLE" == "$BLANK_STRING" ]]; then

        if [ -z "$DEFAULT" ]; then
            error "You should specify default variable"
        else
            VARIABLE="$DEFAULT"
        fi
    fi

   return "$VARIABLE"
}

# Set default variables if needed.
RPCUSER=$(set_default "$RPCUSER" "devuser")
RPCPASS=$(set_default "$RPCPASS" "devpass")
DEBUG=$(set_default "$DEBUG" "debug")
NETWORK=$(set_default "$NETWORK" "regtest")
MACAROON_PATH=$(set_default "$MACAROON_PATH" "/root/.lnd/admin.macaroon")
TLS_CERT_PATH=$(set_default "$TLS_CERT_PATH" "/root/.lnd/tls.cert")
TLS_KEY_PATH=$(set_default "$TLS_KEY_PATH" "/root/.lnd/tls.key")

CHAIN="bitcoin"
BACKEND="bitcoind"

exec lnd \
    --noencryptwallet \
    --logdir="/data" \
    "--$CHAIN.active" \
    "--$CHAIN.$NETWORK" \
    "--$CHAIN.node"="$BACKEND" \
    "--$BACKEND.rpchost"="blockchain" \
    "--$BACKEND.rpcuser"="$RPCUSER" \
    "--$BACKEND.rpcpass"="$RPCPASS" \
    "--$BACKEND.zmqpath"="tcp://blockchain:28332" \
    --adminmacaroonpath="$MACAROON_PATH" \
    --tlscertpath="$TLS_CERT_PATH" \
    --tlskeypath="$TLS_KEY_PATH" \
    --rpclisten=0.0.0.0 \
    --debuglevel="$DEBUG" \
    "$@"
