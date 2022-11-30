#!/bin/bash

setup_firewall() {
  echo "+++ Setting up firewall..."

  # These rules allow us to use the RPi effectively as a proxy - 
  # when we spin up the VPN, this will ensure all traffic comming through here is VPN'd
  # without needing per-device VPN clients
  iptables -A FORWARD -i tun0 -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
  iptables -A FORWARD -i eth0 -o tun0 -j ACCEPT

  iptables-save --file=iptables.v4
}

setup_patching() {
  echo "+++ Setting up cronjob for patching..."
  (crontab -l ; echo "0 2 10 * * /usr/bin/apt update") | crontab
}

# Could be replaced with wireguard?
# XXX THIS ASSUMES THE MULLVAD CONFIG IS AVAILABLE IN THIS DIR
setup_ovpn() {
  echo "+++ Setting up VPN..."
  apt-get install openvpn
  MULLVAD_CONF="mullvad_gb_lon.conf"
  cp $MULLVAD_CONF /etc/openvpn/
  cp "mullvad_ca.crt" /etc/openvpn/
  cp "mullvad_userpass.txt" /etc/openvpn/
  service openvpn start
  curl "https://am.i.mullvad.net/connected"
}

# Alternative to OpenVPN
setup_wireguard() {
  /usr/bin/apt install jq openresolv wireguard
  curl -LO https://mullvad.net/media/files/mullvad-wg.sh
  chmod +x ./mullvad-wg.sh
  ./mullvad-wg.sh
  wg-quick up mullvad-gb11
  curl "https://am.i.mullvad.net/connected"
}

setup_pihole() {
  echo "+++ Setting up pihole..."
  wget -O pihole-install.sh https://install.pi-hole.net
  ./pihole-install.sh
  # TODO load blocklists?
  # TODO configure query logging?
  # TODO configure upstream?
  
}

setup_clamav() {
  echo "+++ Setting up ClamAV..."
  apt-get install clamav

  mkdir /quarantine
  chown root:root /quarantine
  chmod 0700 /quarantine
  mkdir /var/log/clamav
  chown root:root /var/log/clamav
  chmod 0744 /var/log/clamav

  cp virus-scan.sh /root/
  chown root:root /root/virus-scan.sh
  chmod 0700 /root/virus-scan.sh
  (crontab -l ; echo "0 4 * * * /bin/bash /root/virus-scan.sh") | crontab
}

USAGE="USAGE: ./setup-rpi.sh {openvpn | wireguard}"

if [ $# -ne 1 ]
then
    echo "$USAGE"
elif [ "$1" != "openvpn" && "$1" != "wireguard" ]
then
    echo "$USAGE"
else
    setup_firewall
    setup_patching
    setup_pihole

    if [ "$1" != "openvpn" ]
    then 
        setup_ovpn
    else
        setup_wireguard
    fi 

    setup_clamav
    echo "=== SETUP COMPLETE ==="
fi