#!/usr/bin/env bash

POSTCONF="/usr/sbin/postconf"
[[ -x $POSTCONF ]] || exit 1

SUPERVISORD="/usr/bin/supervisord"
[[ -x $SUPERVISORD ]] || exit 1

if [[ -n "$POSTFIX_MYHOSTNAME" ]]; then
	$POSTCONF myhostname=$POSTFIX_MYHOSTNAME
else
	$POSTCONF myhostname=localhost
fi

if [[ -n "$POSTFIX_RELAYHOST" ]]; then
	$POSTCONF relayhost=$POSTFIX_RELAYHOST
else
	$POSTCONF relayhost=
fi

exec $SUPERVISORD --configuration /etc/supervisor/supervisord-docker.conf
