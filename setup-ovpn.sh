#!/bin/bash

echo "+++ Setting up VPN..."
apt-get install openvpn
MULLVAD_CONF="mullvad_gb_lon.conf"
cp $MULLVAD_CONF /etc/openvpn/
cp "mullvad_ca.crt" /etc/openvpn/
cp "mullvad_userpass.txt" /etc/openvpn/
service openvpn start

# These rules allow us to use the RPi effectively as a proxy - 
# when we spin up the VPN, this will ensure all traffic comming through here is VPN'd
# without needing per-device VPN clients
iptables -A FORWARD -i tun0 -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT  # Established connections are permitted to send inbound traffic to be forwarded
iptables -A FORWARD -i eth0 -o tun0 -j ACCEPT # Any outbound traffic is forwarded
iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE  # NAT the ip addresses on the tunnel

curl "https://am.i.mullvad.net/connected"