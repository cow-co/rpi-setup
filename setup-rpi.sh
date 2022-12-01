#!/bin/bash

setup_patching() {
  echo "+++ Setting up cronjob for patching..."
  (crontab -l ; echo "0 2 10 * * /usr/bin/apt update") | crontab
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
    setup_patching
    setup_pihole

    if [ "$1" != "openvpn" ]
    then 
        ./setup-ovpn.sh
    else
        ./setup-wireguard.sh
    fi 

    setup_clamav
    echo "=== SETUP COMPLETE ==="
fi