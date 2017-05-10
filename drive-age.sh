#!/bin/bash

######
## This script was written by SB Tech Services May 2017
## It is completely free for use with no restrictions whatsoever.
##
## Feel free to copy it, modify it, redistribute it, or simply use it
##
## There should be a git repository containing this script at
## http://github.com/sbts/misc-scripts
## If you find any bugs or wish to contribute to this script in any way
## please raise an issue or PR there
##
## While this explicit license is present in this file it overrides the repository license of GPLv3
##
######

VERSION='0.1.1'

Init() {
    local Idx=0;
    declare -g -a Device;
    declare -g -a Model;
    declare -g -a Serial;
    declare -g -a Hours;
    declare -g -a LogHours;
    declare -g -a Temperature;
    declare -g -a TemperatureUnit;

    declare -g SMARTCTL='/usr/sbin/smartctl'
    declare -g SUDO
    if ! [[ $USER == 'root' ]]; then
        [[ ! -u $SMARTCTL ]] && { # "no setUID so try using sudo"
            read -rst5 SUDO < <( which sudo )
            [[ -n "$SUDO" ]] && { echo "sudo not found. please run this script as root"; exit 9; }
            [[ -x "$SUDO" ]] && $SUDO -v -p 'Please enter your [sudo] password so we can run "smartctl -x": '
            read -rst5 SMARTCTL < <( $SUDO which smartctl )
        }
    fi
    [[ ! -x $SMARTCTL ]] && { echo "We don't seem to be able to run 'smartctl' ($SMARTCTL)"; exit 9; }
}

Scan() {
    echo -n 'Scanning drives '
    for Dev in /dev/sd?? ; do
        [[ ${Dev: -1} =~ [0-9] ]] && continue; # if the last char is a number then it's a partition not a device so skip it 
        local Id='' Name='' Flags='' Value='' Worst='' Thresh='' Fail='' Raw='' J1='' J2='' J3='';
        Device[$Idx]="$Dev"
        echo -n "."
        while read -rst10 Id Name Flags Value Worst Thresh Fail Raw J1 J2 J3; do
            [[ "$Id" == 'Device' ]] && [[ "$Name" == 'Model:' ]]  && {
                Model[$Idx]="${Flags} ${Value} ${Worst} ${Thresh} ${Fail} ${Raw} ${J1} ${J2} ${J3}";
                continue;
            }
            [[ "$Id" == 'Serial' ]] && [[ "$Name" == 'Number:' ]] && {
                Serial[$Idx]="${Flags} ${Value} ${Worst} ${Thresh} ${Fail} ${Raw} ${J1} ${J2} ${J3}";
                continue;
            }
            [[ "$Name" == 'Power_On_Hours' ]] && {
                Hours[$Idx]="$Raw";
                continue;
            }
            [[ "$Name" == 'Power_On_Hours_and_Msec' ]] && {
                Hours[$Idx]="${Raw%%h*}";
                continue;
            }
            [[ "$Name" == 'Power-on' ]] && [[ "$Flags" == 'Hours' ]] && {
                Hours[$Idx]="$Raw";
                continue;
            }
            [[ "$Id" == '#' ]] && [[ "$Name" == '1' ]] && {
                LogHours[$Idx]="$J2";
                continue;
            }
            [[ "$Id" == 'Lifetime' ]] && [[ "$Name" == 'Min/Max' ]] && [[ "$Flags" == 'Temperature:' ]] && {
                Temperature[$Idx]="$Value";
                TemperatureUnit[$Idx]="$Worst";
                continue;
            }
        done < <( $SUDO $SMARTCTL -x $Dev)

        [[ -z ${LogHours[$Idx]} ]]        && LogHours[$Idx]=0;
        [[ -z ${Hours[$Idx]} ]]           && Hours[$Idx]=${LogHours[$Idx]}; # Fallback to the "logged" hours if it's available and Power_On_Hours etc are not

        [[ -z ${Model[$Idx]} ]]           && Model[$Idx]='unknown';
        [[ -z ${Serial[$Idx]} ]]          && Serial[$Idx]='unknown';
        [[ -z ${Hours[$Idx]} ]]           && Hours[$Idx]=0;
        [[ -z ${Temperature[$Idx]} ]]     && Temperature[$Idx]='unknown';
        [[ -z ${TemperatureUnit[$Idx]} ]] && TemperatureUnit[$Idx]='unknown';
        (( Idx++ ));
    done
    eval declare -g -a Index=( {0..$(( ${#Device[@]} -1 ))} ); # this just sets a default index order
    echo " : Done"
}

DisplayLines() { # $1 is format, remaining args are values
    local fmt="$1"; shift
    local I=0 maxI=${#Device[@]} J=0;
    while (( I<maxI )); do
        J=${Index[$I]}
        local Hrs=${Hours[$J]}
        local Y=0 D=0 H=0
        (( Y = Hrs/(365*24) ))
        (( H = Hrs % (365*24) ))
        (( D = H/24 ))
        (( H = H%24 ))
        printf "$fmt" "${Device[$J]}" "${Model[$J]}" $Y $D $H "${Temperature[$J]}" "${TemperatureUnit[$J]}"
        (( I++ ))
    done
}

Display(){
    DisplayLines "%-8s - %-30s - %2u Years %3u Days %2u Hours - Temperature (min/max) %s %s\n"
}

Display_Table(){
    local L='--------------------------------------------------------------'
    local I=${#Device[@]};
    printf "  %-8.8s   %-36.36s ,-%5.5s---%4.4s---%5.5s-,-%11.11s-,\n" '' '' "$L" "$L" "$L" "$L"
    printf ",-%-8.8s-,-%-36.36s-| %5s   %4s   %5s | %11.11s |\n" "$L" "$L" '' 'Age' '' ' (min/max) '
    printf "| %-8s | %-36s | %5s | %4s | %5s | %11.11s |\n" 'Device' 'Model' 'Years' 'Days' 'Hours' 'Temperature'
    printf "|-%-8.8s-|-%-36.36s-|-%5.5s-|-%4.4s-|-%5.5s-|-%11.11s-|\n" "$L" "$L" "$L" "$L" "$L" "$L"
    DisplayLines "| %-8s | %-36.36s | %5u | %4u | %5u | %9s %1.1s |\n"
    printf "'-%-8.8s-'-%-36.36s-'-%5.5s-'-%4.4s-'-%5.5s-'-%11.11s-'\n" "$L" "$L" "$L" "$L" "$L" "$L"
}

Build_Index_Sorted() { # $1 = Reverse Sort Order [true|false]
    [[ ${1:-up} == up ]] && Reverse=false;
    [[ ${1:-up} == down ]] && Reverse=true;
    local maxI=${#Index[@]}; #(( maxI -- )) # adjust for zero offset
    unset Index; declare -g -a Index;
    local I=0;
    while (( I<maxI )); do
        local J=0 current=0
        while [[ "z${Index[@]}z" =~ "${current}" ]]; do (( current++ )); done # find first Item not in Index
        while (( J<maxI )); do
            [[ "z"${Index[@]}"z" =~ "${J}" ]] && { (( J++ )); continue; }
            if $Reverse; then
                ! (( ${Hours[$J]} <= ${Hours[$current]} )) && (( current =  J ));
            else
                (( ${Hours[$J]} <= ${Hours[$current]} )) && (( current =  J ));
            fi
            (( J++ ))
        done
        Index[$I]=$current;
        (( I++ ))
    done
}

HELP() {
    cat <<-EOF
	usage: ${0##*/} [-n | -t]
	    -L|l : Line based output
	    -T|t : Table based output
	    -s   : Sort Youngest to Oldest
	    -S   : Sort Oldest to Youngest
	EOF
}

Main() {
    Init
    Scan
    [[ "$@" =~ -[s] ]] && Build_Index_Sorted up
    [[ "$@" =~ -[S] ]] && Build_Index_Sorted down
    [[ "$@" =~ -[tT] ]] && { Display_Table; return; }
    [[ "$@" =~ -[lL] ]] && { Display; return; }
    HELP
}

Main "$@"
