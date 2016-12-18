#!/bin/bash

URL='target_IP_or_Hostname'
User="$USER"

NAME="x2x $URL"

echo "x2x Connected to $URL"
echo -en "\e]2;$NAME\a"

ssh -XC $User@$URL x2x -east -to :0.0 -from :10.0

