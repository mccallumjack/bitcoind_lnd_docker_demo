# Demo of Bitcoind and LND using Docker

This repo contains the docker files for our bitcoind and lnd nodes, as well as some convenience services in the docker-compose file for local testing. By default everything runs in regtest. This is heavily based off the demo and setup in [LND](https://github.com/lightningnetwork/lnd/tree/master/docker). It is not for production use.

## Instructions to Run Locally

#### 1) Spin up your bitcoind node
```
$ docker-compose up -d bitcoind
```

Confirm that it is running with the `bitcoin-cli` service:

```
$ docker-compose run --rm bitcoin-cli getnetworkinfo

{
  "version": 160000,
  "subversion": "/Satoshi:0.16.0/",
  "protocolversion": 70015,
  "localservices": "000000000000040d",
  "localrelay": true,
  "timeoffset": 0,
  "networkactive": true,
  "connections": 0,
  "networks": [
    {
      "name": "ipv4",
      "limited": false,
      "reachable": true,
      "proxy": "",
      "proxy_randomize_credentials": false
    },
    {
      "name": "ipv6",
      "limited": false,
      "reachable": true,
      "proxy": "",
      "proxy_randomize_credentials": false
    },
    {
      "name": "onion",
      "limited": true,
      "reachable": false,
      "proxy": "",
      "proxy_randomize_credentials": false
    }
  ],
  "relayfee": 0.00001000,
  "incrementalfee": 0.00001000,
  "localaddresses": [
  ],
  "warnings": ""
}
```

#### 2) Spin up an LND Node (Alice)
```
$ docker-compose run --rm -d --name alice lnd

# Go into the alice container
$ docker exec -it alice bash

# Check that we are up and running
alice$ lncli --network=regtest getinfo

{
    "identity_pubkey": "028c672ba08dd9f23d2be5a13a7b0221d1c0c71f24ffe1bc2f7a06366bb945b1cb",
    "alias": "022757cfe3ba0e925401",
    "num_pending_channels": 0,
    "num_active_channels": 0,
    "num_peers": 0,
    "block_height": 109,
    "block_hash": "003b45f58b5b83c9b749c9fa7b5d1e115db271a662266c36b8db4e5f972b0da9",
    "synced_to_chain": true,
    "testnet": false,
    "chains": [
        "bitcoin"
    ],
    "uris": [
    ],
    "best_header_timestamp": "1541651988",
    "version": "0.5.0-beta commit="
}
```

## How to demo a transaction locally

#### 1) Create a new lnd node (Bob)

```
$ docker-compose run --rm -d --name bob lnd

$ docker exec -it bob bash

bob$ lncli --network=regtest newaddress np2wkh
{
    "address": "2N7L9vZXJggNVMsmGRwu7seg8LMim1Zhimu"
}
```

#### 2) Generate some new blocks to give Bob some money in a new window

```
# Using address from above.
$ docker-compose run --rm bitcoin-cli generatetoaddress 105 2N7L9vZXJggNVMsmGRwu7seg8LMim1Zhimu
[
  "4764ec4b4f585a1d519376622aad467070e1973d17b5ed596321a1cc9bf96f59",
  "3ec21b6c6e558913289d9533fcc5fed9ad8cd57701243e150f422eaff7d31402",
  ...... etc
]

# Back in bob's shell
bob$ lncli --network=regtest walletbalance
{
    "total_balance": "30000000000",
    "confirmed_balance": "30000000000",
    "unconfirmed_balance": "0"
}
```
We needed to do 105 blocks here because block rewards need > 100 confirmations before they are spendable.

#### 3) Create a channel with Alice from Bob

```
# We need Alice's node's IP Address
$ docker inspect alice | grep IPAddress
IPAdress: 172.21.0.11

# As well as its pubkey
alice$ lncli --network=regtest getinfo
{
    "identity_pubkey": "028c672ba08dd9f23d2be5a13a7b0221d1c0c71f24ffe1bc2f7a06366bb945b1cb", <---- THIS
    "num_pending_channels": 0,
    etc...
}
```

Now back to bob

```
# This will connect us but not create a channel
bob$ lncli --network=regtest connect 028c672ba08dd9f23d2be5a13a7b0221d1c0c71f24ffe1bc2f7a06366bb945b1cb@172.21.0.11

# Confirm we connected
bob$ lncli --network=regtest listpeers
{
    "peers": [
        {
            "pub_key": "028c672ba08dd9f23d2be5a13a7b0221d1c0c71f24ffe1bc2f7a06366bb945b1cb",
            "address": "172.21.0.11:9735",
            "bytes_sent": "7",
            "bytes_recv": "7",
            "sat_sent": "0",
            "sat_recv": "0",
            "inbound": false,
            "ping_time": "0"
        }
    ]
}

# Now fund the channel with the pub_key from above and an amount denoted in satoshis
bob$ lncli --network=regtest openchannel --node_key=028c672ba08dd9f23d2be5a13a7b0221d1c0c71f24ffe1bc2f7a06366bb945b1cb --local_amt=100000
{
  "funding_txid": "60a9807557599e8113e26d3ccc63112310e92478b9f6860dab6ce5e63437381b"
}

# The channel is not open yet because the block hasn't been mined
bob$ lncli listchannels
{
    "channels": [
    ]
}

# So lets mine some blocks in another window (only need 4 now)
$ docker-compose run --rm bitcoin-cli generatetoaddress 4 2N7L9vZXJggNVMsmGRwu7seg8LMim1Zhimu

# Bob should see his channel funded now
bob$ lncli --network=regtest listchannels
{
    "channels": [
        {
            "active": true,
            "remote_pubkey": "028c672ba08dd9f23d2be5a13a7b0221d1c0c71f24ffe1bc2f7a06366bb945b1cb",
            "channel_point": "60a9807557599e8113e26d3ccc63112310e92478b9f6860dab6ce5e63437381b:0",
            .... etc
        }
    ]
}

# We can check from our side and see it there too
docker-compose run --rm lncli --network=regtest listchannels
{
    "channels": [
        {
            "active": true,
            "remote_pubkey": "02072aacaae06edb60c487d6b3c1d8ebfa0b9404ccef95bd1a0abb71be1ea901af",
            "channel_point": "60a9807557599e8113e26d3ccc63112310e92478b9f6860dab6ce5e63437381b:0",
            ... etc
        }
    ]
}
```

#### 3) Create an Invoice for Bob from Alice

```
# Create an invoice for 25000 satoshis
alice$ lncli --network=regtest addinvoice --memo="Hello there" --amt=25000 

{
  "r_hash": "62fccf13f33ae0c46c234ea15b4f322ec87b62d78e4ca094c2fd853e77116143",
  "pay_req": "lnbcrt250u1pdswnmjpp5vt7v7yln8tsvgmprf6s4knej9my8kckh3ex2p9xzlkznuac3v9psdqjfpjkcmr0yp6xsetjv5cqzys4mxdjxy49sz5e0l48usttv6lcqkepp8qz4tdvkzj68h9mufj2699v8p7hnd74vj6x36d29tmm0upt6tdlyce3ad2a970adh4rr5legqqlk9vv9"
}
```

#### 4) Pay the Invoice as Bob
```
# Lets look at the invoice to confirm it is right
bob$ lncli --network=regtest decodepayreq lnbcrt250u1pdswnmjpp5vt7v7yln8tsvgmprf6s4knej9my8kckh3ex2p9xzlkznuac3v9psdqjfpjkcmr0yp6xsetjv5cqzys4mxdjxy49sz5e0l48usttv6lcqkepp8qz4tdvkzj68h9mufj2699v8p7hnd74vj6x36d29tmm0upt6tdlyce3ad2a970adh4rr5legqqlk9vv9
{
    "destination": "02037bc001e2acc783834f125656e3859ed097c4f43480ec6b95d7680d51dc4786",
    "payment_hash": "62fccf13f33ae0c46c234ea15b4f322ec87b62d78e4ca094c2fd853e77116143",
    "num_satoshis": "25000",
    "timestamp": "1527205746",
    "expiry": "3600",
    "description": "Hello there",
    "description_hash": "",
    "fallback_addr": "",
    "cltv_expiry": "144",
    "route_hints": [
    ]
}

# Lets pay it
bob$ lncli --network=regtest payinvoice lnbcrt250u1pdswnmjpp5vt7v7yln8tsvgmprf6s4knej9my8kckh3ex2p9xzlkznuac3v9psdqjfpjkcmr0yp6xsetjv5cqzys4mxdjxy49sz5e0l48usttv6lcqkepp8qz4tdvkzj68h9mufj2699v8p7hnd74vj6x36d29tmm0upt6tdlyce3ad2a970adh4rr5legqqlk9vv9

Description: Hello there
Amount (in satoshis): 25000
Destination: 02037bc001e2acc783834f125656e3859ed097c4f43480ec6b95d7680d51dc4786
Confirm payment (yes/no): yes

{
  "payment_error": "",
  "payment_preimage": "32dd2d4b30d5e6e45b2f88edf395c411ddfb0317b479006711bd2036c8799b66",
  "payment_route": {
    "total_time_lock": 468,
    "total_amt": 500,
    "hops": [
      {
        "chan_id": 352943232581632,
        "chan_capacity": 89950,
        "amt_to_forward": 500,
        "expiry": 468,
        "amt_to_forward_msat": 500000
      }
    ],
    "total_amt_msat": 500000
  }
}
```

#### 5) Check that it was received by Alice
```
alice$ lncli --network=regtest listchannels

{
    "channels": [
        {
            "active": true,
            "remote_pubkey": "02072aacaae06edb60c487d6b3c1d8ebfa0b9404ccef95bd1a0abb71be1ea901af",
            "channel_point": "60a9807557599e8113e26d3ccc63112310e92478b9f6860dab6ce5e63437381b:0",
            "chan_id": "352943232581632",
            "capacity": "100000",
            "local_balance": "25000",
            "remote_balance": "75000",
            "commit_fee": "9050",
            "commit_weight": "724",
            "fee_per_kw": "12500",
            "unsettled_balance": "0",
            "total_satoshis_sent": "0",
            "total_satoshis_received": "25000",
            "num_updates": "6",
            "pending_htlcs": [
            ],
            "csv_delay": 144,
            "private": false
        }
    ]
}
```

### 6) Profit!


