#!/bin/bash

/usr/bin/apt install jq openresolv wireguard
curl -LO https://mullvad.net/media/files/mullvad-wg.sh
chmod +x ./mullvad-wg.sh
./mullvad-wg.sh
wg-quick up mullvad-gb11

# These rules allow us to use the RPi effectively as a proxy - 
# when we spin up the VPN, this will ensure all traffic comming through here is VPN'd
# without needing per-device VPN clients
iptables -A FORWARD -i "mullvad-gb11" -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT  # Established connections are permitted to send inbound traffic to be forwarded
iptables -A FORWARD -i eth0 -o "mullvad-gb11" -j ACCEPT # Any outbound traffic is forwarded
iptables -t nat -A POSTROUTING -o "mullvad-gb11" -j MASQUERADE  # NAT the ip addresses on the tunnel
iptables-save --file=iptables.v4

curl "https://am.i.mullvad.net/connected"