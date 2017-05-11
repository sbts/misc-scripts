#!/bin/bash

declare -a hosts
hosts=( 'localhost' )
#hosts+=( 'another_host.local' )

declare results=''

for h in ${hosts[@]}; do
    results+='=========================='$'\n'
    results+="== $h"$'\n'
    results+='=========================='$'\n'

    if [[ $h == $HOSTNAME ]]; then
        results+=`sensors -A`
    else
        results+=`ssh $h sensors -A`
    fi
    results+=$'\n'
    results+=$'\n'

done

clear;
date
printf "$results\n"
