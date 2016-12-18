#!/bin/bash


#####
# NOTE: HOSTNAME(7) details the use of HOSTALIASES to do something similar, but it has limitations and uses a different file format to /etc/hosts
#       It does however work for most programs if the limitations are taken into account
#####
# These functions make ~/.hosts behave like a simple override for /etc/hosts, but ONLY for commands explicitly listed in this file.
#       currently that only includes ping, traceroute, ssh

function resolve {
        hostfile=~/.hosts
        if [[ -f "$hostfile" ]]; then
                for arg in $(seq 1 $#); do
                        if [[ "${!arg:0:1}" != "-" ]]; then
                                ip=$(sed -n -e "/^\s*\(\#.*\|\)$/d" -e "/\<${!arg}\>/{s;^\s*\(\S*\)\s*.*$;\1;p;q}" "$hostfile") #"# klude syntax highliting in MC
                                if [[ -n "$ip" ]]; then
                                        command "${FUNCNAME[1]}" "${@:1:$(($arg-1))}" "$ip" "${@:$(($arg+1)):$#}"
                                        return
                                fi
                        fi
                done
        fi
        command "${FUNCNAME[1]}" "$@"
}

function ping {
        resolve "$@"
}

function traceroute {
        resolve "$@"
}

function ssh {
        resolve "$@"
}
