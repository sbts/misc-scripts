#!/bin/bash

echo
echo '########################'

ip -4 -o addr
echo

ip -4 route
echo

cat /etc/resolv.conf
echo
echo '########################'
echo
