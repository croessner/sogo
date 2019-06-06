#!/bin/bash

trap "break;exit" SIGHUP SIGINT SIGTERM

declare -i run=0

while true; do
  H=$(date +%H)
  M=$(date +%M)
  if [[ "$H" = "00" && "$M" = "00" ]]; then
    if [[ $run -eq 0 ]]; then
      echo "$(date +"%Y-%m-%d %H:%M:%S"): Running sogo-tool update-autoreply -p /etc/sogo/sieve.creds"
      /usr/local/sbin/sogo-tool update-autoreply -p /etc/sogo/sieve.creds
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
