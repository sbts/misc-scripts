#!/bin/bash

SysPrefix='/sys/class/thermal'

ReadSysFile() { # $1 sys filename to read not including $SysPrefix
    declare -g Tmp=''
#echo -n 'y'
    [[ -r "$D/$1" ]] && {
#echo -n 'z'
        read -rst5 Tmp < "$D/$1"
    }
}
ScanThermalZone() {
    echo -n 'Scanning Thermal Zone: '
    Idx=0
    declare -g -a Name Type Current Max Other
    for D in ${SysPrefix}/*; do
        echo -n "."
        Name[$Idx]=${D##*/}
        [[ -r $D/type ]]      && read -rst5 Type[$Idx]    J < $D/type
        [[ -r $D/cur_state ]] && read -rst5 Current[$Idx] J < $D/cur_state
        [[ -r $D/max_state ]] && read -rst5 Max[$Idx]     J < $D/max_state

        [[ ${Type[$Idx]} == 'Processor' ]] && {
            ReadSysFile 'device/path'
            Name[$Idx]="${Tmp##*.} (${Name[$Idx]##*[a-z]})"
        }

        [[ ${Type[$Idx]} == 'Fan' ]] && {
            ReadSysFile 'device/firmware_node/path'
            Name[$Idx]="${Tmp##*.} (${Name[$Idx]##*[a-z]})"

            ReadSysFile 'device/firmware_node/real_power_state'
            Other[$Idx]="$Tmp"
        }

        [[ ${Type[$Idx]} == 'intel_powerclamp' ]] && {
            ReadSysFile 'power/control'
            Other[$Idx]="$Tmp"
        }

        [[ ${Type[$Idx]} == 'acpitz' ]] || \
            [[ ${Type[$Idx]} == 'x86_pkg_temp' ]] && {
                ReadSysFile 'temp'
                Current[$Idx]="${Tmp:0:-3}.${Tmp: -3:-2}"
                ReadSysFile 'policy'
                Other[$Idx]="${Tmp}"
                ReadSysFile 'power/control'
                Other[$Idx]+=" - ${Tmp}"
        }

        (( Idx++ ))
    done
    echo ' - Done'
}

PrintType() { # $1 is Type regex
    I=0
    while (( I < ${#Type[@]} )); do
        [[ ! ${Type[$I]} == ${1:-.*} ]] && { (( I++ )); continue; }
        printf "| %-18s | %-16s | %5s | %3s | %20s |\n" "${Name[$I]}" "${Type[$I]}" "${Current[$I]}" "${Max[$I]}" "${Other[$I]}"
        (( I++ ))
    done
}

Print() {
    Line='--------------------------------------------------------------------'
    Printed=''
    printf ",-%-18.18s-,-%-16.16s-,-%5.5s-,-%3.3s-,-%20.20s-,\n" $Line $Line $Line $Line $Line
    printf "| %-18.18s | %-16.16s | %5.5s | %3.3s | %20.20s |\n" 'Name' 'Type' 'Now' 'Max' 'Other'
#    printf "|-%-18.18s-|-%-16.16s-|-%3.3s-|-%3.3s-|\n" $Line $Line $Line $Line
    for T in "${Type[@]}"; do
        [[ "$Printed" =~ $T ]] && continue; # We have already printed that type
        printf "|-%-18.18s-|-%-16.16s-|-%5.5s-|-%3.3s-|-%20.20s-|\n" $Line $Line $Line $Line $Line
        PrintType "$T"
        Printed+=" $T"
    done
    printf "'-%-18.18s-'-%-16.16s-'-%5.5s-'-%3.3s-'-%20.20s-'\n" $Line $Line $Line $Line $Line
}

Main() {
    ScanThermalZone
    Print
}

Main
exit

