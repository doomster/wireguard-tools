#!/bin/bash

# ADD HERE YOUR INVENTORY FILE NAME, YOUR WG_CONF_FILE, YOUR PUBLIC SERVER KEY, YOUR ENDPOINT IN THE FORM OF FQDN:PORT. IP BASE IS THE SUBNET YOU WANT YOUR CLIENTS TO USE, IN THIS CASE 10.0.10.0/24
INVENTORY_FILE="peer_inventory.txt"
WG_CONF_FILE="/etc/wireguard/wg0.conf"
SERVER_KEY=""
SERVER_ENDPOINT=""
IP_BASE="10.0.10"
# Prompt for the peer name
read -p "Enter the peer name: " PEER_NAME

# Generate the private and public keys for the peer
wg genkey | tee "${PEER_NAME}_private.key" | wg pubkey > "${PEER_NAME}_public.key"

# Get the public key
PUBLIC_KEY=$(cat "${PEER_NAME}_public.key")
PRIVATE_KEY=$(cat "${PEER_NAME}_private.key")

# Find the next available IP address in the subnet 10.0.10.0/24
# Assume that the first two IPs are used: 10.0.10.1 and 10.0.10.2 (one is for the server and two is backup
COUNTER=2
# Function to increment IP address
increment_ip() {
    local ip=$1
    local base=$(echo "$ip" | cut -d. -f1-3)
    local last_octet=$(echo "$ip" | cut -d. -f4)
    echo "$base.$((last_octet + 1))"
}

# Find the next available IP address
NEXT_IP="$IP_BASE.$COUNTER"
while grep -q "$NEXT_IP" "$INVENTORY_FILE"; do
    COUNTER=$((COUNTER + 1))
    NEXT_IP=$(increment_ip "$IP_BASE.$COUNTER")
done
# Add the new peer info to the inventory file
echo "$PEER_NAME $PUBLIC_KEY $NEXT_IP" >> "$INVENTORY_FILE"
# Display the inventory file entry
echo "Added to inventory: $PEER_NAME $PUBLIC_KEY $NEXT_IP"
echo ""
# Add the peer configuration to the wg0.conf file
echo "[Peer]" >> "$WG_CONF_FILE"
echo "PublicKey = $PUBLIC_KEY" >> "$WG_CONF_FILE"
echo "AllowedIPs = $NEXT_IP/32" >> "$WG_CONF_FILE"

# Restart the WireGuard service
sudo systemctl restart wg-quick@wg0.service

if [ $? -eq 0 ]; then
    echo "WireGuard service restarted successfully."
else
    echo "Failed to restart WireGuard service."
fi

# Create the client config file
CLIENT_CONFIG="${PEER_NAME}_wg0.conf"
cat <<EOL > "$CLIENT_CONFIG"
[Interface]
PrivateKey = $(cat ${PEER_NAME}_private.key)
Address = $NEXT_IP/32
DNS = 8.8.8.8

[Peer]
PublicKey = $SERVER_KEY
Endpoint = $SERVER_ENDPOINT
AllowedIPs = $IP_BASE.1/24
PersistentKeepalive = 21
EOL

#Used to add several Mikrotik Routers to the wireguard without hussle.
#echo "Add this to Mikrotik"
#echo "/interface wireguard add listen-port=13231 mtu=1420 name=zms private-key=\"$PRIVATE_KEY\""
#echo "/ip address add address=$NEXT_IP/24 interface=zms network=$IP_BASE.0"
#echo "/interface wireguard peers add allowed-address=IP_BASE.0/24 endpoint-address=example.com endpoint-port=PORT interface=zms persistent-keepalive=1m public-key=\"$SERVER_KEY\""
#echo ""

echo "Client configuration file created: $CLIENT_CONFIG"
echo ""
echo "QR Code:"
qrencode -t ansiutf8 $CLIENT_CONFIG
