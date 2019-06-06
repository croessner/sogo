#!/bin/bash

trap "break;exit" SIGHUP SIGINT SIGTERM

chown -R sogo:sogo /home/sogo/backups

declare -i run=0

while true; do
  H=$(date +%H)
  M=$(date +%M)
  if [[ "$H" = "05" && "$M" = "30" ]]; then
    if [[ $run -eq 0 ]]; then
      echo "$(date +"%Y-%m-%d %H:%M:%S"): Running sogo-backup.sh"
      su - sogo -c "/sogo-backup.sh"
      run=1
    fi
  else
    if [[ $run -eq 1 ]]; then
      run=0
    fi
  fi
  sleep 1
done

exit 0
