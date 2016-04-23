#!/bin/bash
BASE_PATH=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

newconf=$($BASE_PATH/dag4s.sh $1)
cat $newconf > /etc/squid3/squid.conf
kill -HUP $(cat /var/run/squid3.pid)
