#!/bin/bash

# Define the inventory file
INVENTORY_FILE="peer_inventory.txt"

# Check if the inventory file exists
if [ ! -f "$INVENTORY_FILE" ]; then
    echo "Inventory file not found!"
    exit 1
fi

# Create an associative array to map public keys to peer names
declare -A peer_map

# Read the inventory file and populate the peer_map
while read -r line; do
    peer_name=$(echo "$line" | awk '{print $1}')
    public_key=$(echo "$line" | awk '{print $2}')
    peer_map["$public_key"]="$peer_name"
done < "$INVENTORY_FILE"

# Get the output of the wg command
wg_output=$(wg show)

# Replace public keys with peer names
for public_key in "${!peer_map[@]}"; do
    peer_name=${peer_map[$public_key]}
    # Escape special characters in the public key
    escaped_public_key=$(echo "$public_key" | sed -e 's/[\/&]/\\&/g')
    wg_output=$(echo "$wg_output" | sed "s/$escaped_public_key/$peer_name/")
done

# Output the modified wg command result
echo "$wg_output"
