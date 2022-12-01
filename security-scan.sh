#!/bin/bash

# Does an assortment of security checks:
# - ClamAV scan
# - Check for non-root UID=0 users
# - Check for SUID files
# - Check for failed logins
# - Ensures certain specific services are disabled

DATE=$(/bin/date +'%Y-%m-%d')
SECLOGDIR="/root/security-scan/${DATE}"
/bin/mkdir "/root/security-scan/"
/bin/mkdir "/root/security-scan/${DATE}"
/bin/chown root:root "/root/security-scan/"
/bin/chmod 0700 "/root/security-scan/"
/bin/chown root:root "/root/security-scan/${DATE}"
/bin/chmod 0700 "/root/security-scan/${DATE}"

CLAMLOG="/var/log/clamav/scan-${DATE}.log"
/usr/bin/clamscan -ir -f "./clamav-targets.txt" -l "$CLAMLOG"
INFECTED=$(/bin/cat "$CLAMLOG" | /bin/grep "Infected files: 0\b")

if [ ! -z $INFECTED ]
then
    /bin/echo "THERE ARE INFECTED FILES: " > "${SECLOGDIR}infected.txt"
    /bin/echo "${INFECTED}" >> "${SECLOGDIR}infected.txt"
fi

UIDZERO=$(/bin/cat /etc/passwd | /usr/bin/awk -F ":" '{print $1,$3}' | /bin/grep "\b0\b" | awk -F " " '{print $1}')
UIDZEROARR=($UIDZERO)
if [ ${#UIDZEROARR[@]} -ne 1 ]
then
    /bin/echo "${UIDZEROARR[@]}" > "${SECLOGDIR}uid-zeros.txt"
fi

declare -a AUDITWATCHLIST=("iptables" "cp" "bash" "chown" "chmod" "systemctl" "service" "vi" "vim" "nano")
AUDITDATE=$(/bin/date +'%b %_d')

for WATCH in "${AUDITWATCHLIST[@]}"
do
    /bin/cat /var/log/auth.log | /bin/grep "$AUDITDATE" | /bin/grep "$WATCH" > "${SECLOGDIR}audit.txt"
done

/bin/cat /var/log/auth.log | /bin/grep "$AUDITDATE" | /bin/grep "Failed password" > "${SECLOGDIR}fail-logins.txt"

/usr/bin/find / -perm /4000 > "${SECLOGDIR}suid-files.txt"
/usr/bin/find / -perm /2000 > "${SECLOGDIR}sgid-files.txt"
/usr/bin/find / -perm /6000 > "${SECLOGDIR}suid-sgid-files.txt"
# TODO filter out safe suids/sgids (eg. sudo)