# wireguard-tools
Scripts that helped me manage my wireguard installation.

The generate-peers.sh script  
 takes as an input the name of the peer you would like to add, creates a keypair for it, creates a conf file from it using a free address from a defined pool, and generates the qr code so that you can add it to a device. Finally it adds the peers name, the defined address and its public key into a list file called peer_inventory.txt.

The wgstatus.sh script  uses the above list to run wg command, and replace the arbitary peer keys from the output to the defined peer names from the above list. 

EG output:

interface: wg0
  public key: iwouldntpostanactualkeyhere
  private key: (hidden)
  listening port: 13531

peer: customer1
  endpoint: 85.74.43.67:13231
  allowed ips: 10.0.10.5/32
  latest handshake: 8 seconds ago
  transfer: 164.94 KiB received, 62.26 KiB sent

peer: customer23
  endpoint: 2.86.196.191:13231
  allowed ips: 10.0.10.4/32
  latest handshake: 30 seconds ago
  transfer: 164.02 KiB received, 62.43 KiB sent
