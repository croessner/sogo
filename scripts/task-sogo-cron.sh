#!/bin/bash

trap "break;exit" SIGHUP SIGINT SIGTERM

while true; do
  S=$(date +%S)
  if [[ "$S" = "00" ]]; then
    echo "$(date +"%Y-%m-%d %H:%M:%S"): Running sogo-tool expire-sessions 60"
    /usr/local/sbin/sogo-tool expire-sessions 60
    echo "$(date +"%Y-%m-%d %H:%M:%S"): Running sogo-ealarms-notify"
    /usr/local/sbin/sogo-ealarms-notify
  fi
  sleep 1
done

exit 0
