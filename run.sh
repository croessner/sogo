#!/usr/bin/env bash

POSTCONF="/usr/sbin/postconf"
[[ -x $POSTCONF ]] || exit 1

SUPERVISORD="/usr/bin/supervisord"
[[ -x $SUPERVISORD ]] || exit 1

if [[ -n "$POSTFIX_MYHOSTNAME" ]]; then
	$POSTCONF -e myhostname=$POSTFIX_MYHOSTNAME
else
	$POSTCONF -e myhostname=localhost
fi

if [[ -n "$POSTFIX_RELAYHOST" ]]; then
	$POSTCONF -e relayhost=$POSTFIX_RELAYHOST
else
	$POSTCONF -e relayhost=
fi

exec $SUPERVISORD --configuration /etc/supervisor/supervisord-docker.conf
