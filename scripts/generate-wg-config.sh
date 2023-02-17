#!/bin/bash

# --------------------------------------------------------------------
# This script generates the wireguard config file for the server.
# --------------------------------------------------------------------
#
# Author:  Benjamin Kulnik
# Date:    2023-02-16
# Version: 0.1

# Tune this configurations for your instance
INTERFACE_NAME="ens5"
INSTANCE_PUBLIC_ENDPOINT=""
TUNNEL_IP_PREFIX="100.64.0"
TUNNEL_IP6_PREFIX="fd00:ec2:cafe:0000"
OUTPUT_DIR="./etc-wireguard"
OUTPUT_FILE="wg0.conf"
N=10 # Generate 10 client configurations


test -z "$INSTANCE_PUBLIC_ENDPOINT" && echo "Please set INSTANCE_PUBLIC_ENDPOINT" && exit 1


# Alternative way: Define the public keys of the clients instead of generating them
#PEER_PUB_KEYS=("E3QVDASgGpcynlGnjZM6vxd10waLs1DTYM4GFNJJ7Rc=")
# ${#array[@]} is the number of elements in the array
#N=${#PEER_PUB_KEYS[@]}


set -euo pipefail # we wan't to exit if any command fails - no silent errors


OUTPUT_PATH="$(pwd)/$OUTPUT_DIR/$OUTPUT_FILE"


# Define colors
RED='\033[0;31m'
ORANGE='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m'

# Create folder and file
mkdir -p $OUTPUT_DIR
touch $OUTPUT_PATH

# generate keys
SERVER_PRIVATE_KEY=$(wg genkey)
SERVER_PUBLIC_KEY=$(echo "$SERVER_PRIVATE_KEY" | wg pubkey)

# write to config

echo "
[Interface]
# PublicKey = $SERVER_PUBLIC_KEY
PrivateKey = $SERVER_PRIVATE_KEY
Address = $TUNNEL_IP_PREFIX.1/32, $TUNNEL_IP6_PREFIX::1/128
ListenPort = 51820
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o $INTERFACE_NAME -j MASQUERADE; ip6tables -A FORWARD -i wg0 -j ACCEPT; ip6tables -t nat -A POSTROUTING -o $INTERFACE_NAME -j MASQUERADE # Add forwarding when VPN is started
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o $INTERFACE_NAME -j MASQUERADE; ip6tables -D FORWARD -i wg0 -j ACCEPT; ip6tables -t nat -D POSTROUTING -o $INTERFACE_NAME -j MASQUERADE # Remove forwarding when VPN is shutdown
" > $OUTPUT_PATH


# This is the loop that generates the client configs
for ((i = 0; i < $N; ++i)); do

    echo -e "${ORANGE}Generating client $i...${NC}"

    # Get the public key
    # pub_key=${PEER_PUB_KEYS[$i]}
    client_secret_key=$(wg genkey)
    client_pub_key=$(echo "$client_secret_key" | wg pubkey)

    # Generate the client tunnel ip
    client_address_sufix=$(($i + 2))
    client_tunnel_ip="$TUNNEL_IP_PREFIX.$client_address_sufix/32"
    client_tunnel_ip6="$TUNNEL_IP6_PREFIX::$client_address_sufix/128"

    # Append to server config
    echo "
[Peer]
PublicKey = $client_pub_key
AllowedIPs = $client_tunnel_ip, $client_tunnel_ip6
    " >> "$OUTPUT_PATH"


    # Create the client config
    echo "
[Interface]
PrivateKey = $client_secret_key
Address = $client_tunnel_ip, $client_tunnel_ip6
DNS = 9.9.9.9, 149.112.112.112, 2620:fe::fe, 2620:fe::9

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = $INSTANCE_PUBLIC_ENDPOINT:51820
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
    " > $OUTPUT_DIR/client-$i.conf



    # Create a qrcode for the client
    qrencode -t ansiutf8 < $OUTPUT_DIR/client-$i.conf > $OUTPUT_DIR/client-$i.qr

    qrencode -t png -d 200 -o "$OUTPUT_DIR/client-$i.png" < $OUTPUT_DIR/client-$i.conf 

done


echo -e "${GREEN}Done.${NC}"
echo "Server config is in $OUTPUT_PATH"
echo "Client configs are in $OUTPUT_DIR/client-*.conf"
