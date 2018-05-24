FROM ubuntu:xenial

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C70EF1F0305A1ADB9986DBD8D46F45428842CE5E && \
    echo "deb http://ppa.launchpad.net/bitcoin/bitcoin/ubuntu xenial main" > /etc/apt/sources.list.d/bitcoin.list

RUN apt-get update && apt-get install -y --no-install-recommends \
    bitcoind \
  && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Expose mainnet ports (server, rpc)
EXPOSE 8333 8334

# Expose testnet ports (server, rpc)
EXPOSE 18333 18334

# Expose regtest ports (server, rpc)
EXPOSE 18443 18444

# ZMQ
EXPOSE 28332

WORKDIR /bitcoin

COPY "start-bitcoind.sh" .
COPY "start-bitcoin-cli.sh" .

RUN chmod +x start-bitcoind.sh
