#!/bin/bash
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
NETWORK=$(set_default "$NETWORK" "regtest")

PARAMS=$(echo \
    "-$NETWORK=1" \
    "-rpcuser=$RPCUSER" \
    "-rpcpassword=$RPCPASS" \
    -datadir=/bitcoin/.bitcoin \
    -rpcallowip=::/0 \
    -zmqpubrawblock=tcp://*:28332 \
    -zmqpubrawtx=tcp://*:28332 \
    -txindex \
    -disablewallet \
    -printtoconsole
)

# Add user parameters to command.
PARAMS="$PARAMS $@"

# Print command and start bitcoin node.
echo "Command: bitcoind $PARAMS"
exec bitcoind $PARAMS
