#!/bin/bash
LOGFILE="/var/log/clamav/scan-$(date -d '%Y-%m-%d').log"
SCANDIRS="/home /root"
clamscan -ir "$SCANDIRS" &>"$LOGFILE"