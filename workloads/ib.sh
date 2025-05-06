#!/bin/bash

SERV=cn-priv-23
CLIENT=cn-priv-24

if [ $# -lt 1 ]; then
	echo "USAGE: $0 <ib_cmd>"
fi

cleanup () {
echo "Cleaning up $!"
	kill $TO_KILL 

}
trap cleanup SIGINT
ssh $SERV "$@" &
TO_KILL=$!
ssh $CLIENT $@ $SERV



