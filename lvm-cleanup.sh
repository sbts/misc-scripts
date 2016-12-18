#!/bin/bash

clear;
cat <<-EOF
	
	        ==================================================================
	        == The following is a list of LVM Volumes                       ==
	        ==                                                              ==
	        == You should only remove them if                               ==
	        ==      a: you know what you are doing                          ==
	        ==      b: they are on drives that are no longer connected      ==
	        ==      c: they have an "Open count" of 0                       ==
	        ==                                                              ==
	        ==================================================================
	
EOF

trim() { # shamelessly ripped from http://stackoverflow.com/a/7486606
    # Determine if 'extglob' is currently on.
    local extglobWasOff=1
    shopt extglob >/dev/null && extglobWasOff=0 
    (( extglobWasOff )) && shopt -s extglob # Turn 'extglob' on, if currently turned off.
    # Trim leading and trailing whitespace
    local var=$1
    var=${var##+([[:space:]])}
    var=${var%%+([[:space:]])}
    (( extglobWasOff )) && shopt -u extglob # If 'extglob' was off before, turn it back off.
    echo -n "$var"  # Output trimmed string.
}

LIST_Unused_Volumes() {
    sudo dmsetup info | grep -B4 -A3 'Open count.* .$'
}

PrintTableHeader() {
    printf ",----------------------------------------------------,---------,-------,---------,-------,--------,---------------,-----------,------------,\n"
    printf "| %-50s | %-7s | %-5s | %-7s | %-5s | %-6s | %-13s | %-9s | %-10s |\n" 'Name' 'State' 'Read'  'Tables'  'Open'  'Event'  'Major, minor' 'Number of' 'Physical'
    printf "| %-50s | %-7s | %-5s | %-7s | %-5s | %-6s | %-13s | %-9s | %-10s |\n" ''     ''      'Ahead' 'present' 'count' 'number' 'Major, minor' 'targets'   'Devices'
    printf "|----------------------------------------------------+---------+-------+---------+-------+--------+---------------+-----------|------------|\n"
}

PrintTableFooter() {
    printf "'----------------------------------------------------'---------'-------'---------'-------'--------'---------------'-----------'------------'\n"
}

PrintTableLine() {
    Major="${Major_minor%%,*}";
    Minor="${Major_minor##*, }";
    Bold_=`tput smso`; Normal=`tput rmso`;
    if [[ -r "/sys/dev/block/$Major:$Minor/slaves" ]]; then
        read -t5 Devices < <( ls "/sys/dev/block/$Major:$Minor/slaves" )
    else
        Devices='';
    fi
    if (( Open_count == 0)); then Bold="$Bold_"; else Bold="$Normal"; fi
    if (( Entries == 0)); then Bold="$Normal"; fi
    printf "| ${Bold}%-50s | %-7s | %4s  | %-7s | %4s  | %5s  |    %-10s | %8s  | %-10s${Normal} |\n" "$Name" "$State" "$Read_Ahead" "$Tables_present" "$Open_count" "$Event_number" "$Major_minor" "$Number_of_targets" "$Devices";
    tput rmso;
    Name=''; State=''; Read_Ahead=''; Tables_present=''; Open_count=''; Event_number=''; Major_minor=''; Number_of_targets='';
}

DumpTable() {
    IFSold="$IFS"
    IFS=':'
    Entries=0;

    sudo -v -p 'Please enter the password for %p to run some commands as %U on %H: '

    PrintTableHeader;
    while read -t5  Key Value Junk; do
        Key="$(trim "$Key")";
#        Value="$(trim "$Value")";
        case "$Key" in
                           '--') PrintTableLine;;
                         'Name') Name="$(trim "$Value")"; (( Entries++ ));;
                        'State') State="$(trim "$Value")";;
                   'Read Ahead') Read_Ahead="$(trim "$Value")";;
               'Tables present') Tables_present="$(trim "$Value")";;
                   'Open count') Open_count="$(trim "$Value")";;
                 'Event number') Event_number="$(trim "$Value")";;
                 'Major, minor') Major_minor="$(trim "$Value")";;
            'Number of targets') Number_of_targets="$(trim "$Value")";;
        esac
    done < <(LIST_Unused_Volumes)
    PrintTableLine;
    PrintTableFooter;
    IFS="$IFSold"
}

DumpList() {
    IFSold="$IFS"
    IFS=':'
    while read -t5  Key Value Junk; do
        if [[ $Key == '--' ]]; then echo; continue; fi
        Key="$(trim "$Key")";
        Value="$(trim "$Value")";
        printf "%-17s %s\n" "$Key" "$Value"
    done < <(LIST_Unused_Volumes)
    IFS="$IFSold"
}

LV_Remove() { # requires exactly one argument, the name of the LV to remove from the displayed table
    if (( ${#@} == 1 )); then
        sudo dmsetup remove $1
            # similar can be done by running
            # lsscsi and selecting the correct device to pass to
            # # echo 1 > /sys/class/scsi_device/2\:0\:1\:0/device/delete
    elif (( ${#@} == 0 )); then
        exit 0
    else
        echo "Exactly 1 argument is required by LV_Remove()"
        echo "You supplied ${#@}"
        echo "${@}"
        exit 1
    fi
}

DumpTable
read -e -p 'Enter LV to remove [NULL to exit]: ' LV
LV_Remove $LV
