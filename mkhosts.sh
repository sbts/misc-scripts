#!/bin/bash


#interesting bash command....
#    http://wiki.bash-hackers.org/commands/builtin/mapfile


#interface="`ip route show proto static`"; interface="${interface% *}"  # trim trailing spaces
#interface="${interface##* }"  # trim everything upto device name

# get default route interface name and IP address
read j j gw j interface j ip j < <(ip route get 1);  #j is a junk variable, it can be used more than once.
mac=`< /sys/class/net/$interface/address`

temphosts="/tmp/hosts-"`date "+%s"`
trap 'rm -f "$temphosts"' EXIT

declare hosts_XEN
declare hosts_BARE_METAL
declare hosts_INFRASTRUCTURE

declare -a hosts_addr
declare -a hosts_mac
declare -a hosts_name
declare -a hosts_comment
declare -a hosts_catagory
declare -a hosts_XEN_addr
declare -a hosts_XEN_mac
declare -a hosts_XEN_name
declare -a hosts_XEN_comment
declare -a hosts_BARE_METAL_addr
declare -a hosts_BARE_METAL_mac
declare -a hosts_BARE_METAL_name
declare -a hosts_BARE_METAL_comment
declare -a hosts_INFRASTRUCTURE_addr
declare -a hosts_INFRASTRUCTURE_mac
declare -a hosts_INFRASTRUCTURE_name
declare -a hosts_INFRASTRUCTURE
declare -a hosts_Unknown_addr
declare -a hosts_Unknown_mac
declare -a hosts_Unknown_name
declare -a hosts_Unknown_comment

#hosts_addr
#hosts_mac
#hosts_name
#hosts_comment
#hosts_catagory
#hosts_XEN_addr
#hosts_XEN_mac
#hosts_XEN_name
#hosts_XEN_comment
#hosts_BARE_METAL_addr
#hosts_BARE_METAL_mac
#hosts_BARE_METAL_name
#hosts_BARE_METAL_comment
#hosts_INFRASTRUCTURE_addr
#hosts_INFRASTRUCTURE_mac
#hosts_INFRASTRUCTURE_name
#hosts_INFRASTRUCTURE
#hosts_Unknown_addr
#hosts_Unknown_mac
#hosts_Unknown_name
#hosts_Unknown_comment



Write_HOSTS_header() {
	cat <<-EOF >"$temphosts"
		127.0.0.1<----->localhost
		127.0.1.1<----->$HOSTNAME

		# The following lines are desirable for IPv6 capable hosts
		::1     ip6-localhost ip6-loopback
		fe00::0 ip6-localnet
		ff00::0 ip6-mcastprefix
		ff02::1 ip6-allnodes
		ff02::2 ip6-allrouters

		$ip	$HOSTNAME-$interface

	EOF

}

Write_HOSTS() {
    echo "# "
    hosts_XEN
    hosts_BARE_METAL
    hosts_INFRASTRUCTURE
}

ARP_SCAN() {
#    cat <<-EOF 
#	===========================================================================
#	    arp-scan -l -N -I $interface | egrep '([0-9a-f]{2}:){5}';
#	===========================================================================
#EOF
    arp-scan -l -N -I $interface | egrep '([0-9a-f]{2}:){5}';
}

Lookup_MAC_CompanyName() {
                oldIFS=$IFS;
                IFS=\|;
                  read -t60 s e s e Company j < <(wget -O /dev/stdout -q http://www.macvendorlookup.com/api/v2/${mac:0:-6}/pipe) ;  # strip the last 6 chars from mac address to minimise leaked information
                IFS=$oldIFS;
}

HostNameLookup() { # 1 argument is IP address to find hostname for
    :
}
ArpScanHosts() {
    local addr
    local mac
    local comment
    local junk
    local fingerprint
    local Hostname
    local UnknownCtr=1
    while read -t60 addr mac comment; do
        if (( ${#addr} >= 7 )); then
            echo "getting info for IP '$addr'"
            read -t60 j j fingerprint < <(arp-fingerprint -o "-N -I $interface" $addr; echo)
echo -n .
            read -t60 Hostname < <([[ $fingerprint =~ [Ll]inux ]] && ssh $USER@$addr Hostname 2>/dev/null)
echo -n .
            Hostname=${Hostname:-unknown$(( UnknownCtr++ ))}
#            if [[ "$fingerprint" =~ 'Xensource' ]]; then { hosts_XEN_addr+="$addr"; hosts_XEN_mac+="$mac"; hosts_XEN_name+="$Hostname"; hosts_XEN_comment+="$comment ##fingerprint==$fingerprint'"; }
            if [[ "$comment" =~ '(Unknown)' ]]; then # check for unknown devices first so we can try doing a web lookup
                Lookup_MAC_CompanyName; # stores result in "$Company"
                comment+=" lookup:$Company";
                catagory='unknown'; hosts_Unknown_addr+="$addr"; hosts_Unknown_mac+="$mac"; hosts_Unknown_name+="$Hostname"; hosts_Unknown_comment+="$comment ##fingerprint==$fingerprint'";
            fi
            if [[ "$comment" =~ 'Xensource' ]]; then { catagory='xen'; hosts_XEN_addr+="$addr"; hosts_XEN_mac+="$mac"; hosts_XEN_name+="$Hostname"; hosts_XEN_comment+="$comment ##fingerprint==$fingerprint'"; }
              elif [[ "$mac" =~ ^'00:16:3e' ]]; then { catagory='xen'; hosts_XEN_addr+="$addr"; hosts_XEN_mac+="$mac"; hosts_XEN_name+="$Hostname"; hosts_XEN_comment+="$comment ##fingerprint==$fingerprint'"; }
                elif [[ "$comment" =~ 'Hewlett' ]]; then { catagory='infrastructure'; hosts_INFRASTRUCTURE_addr+="$addr"; hosts_INFRASTRUCTURE_mac+="$mac"; hosts_INFRASTRUCTURE_name+="$Hostname"; hosts_INFRASTRUCTURE_comment+="$comment ##fingerprint==$fingerprint'"; }
                elif [[ "$comment" =~ 'NETCOMM' ]]; then { catagory='infrastructure'; hosts_INFRASTRUCTURE_addr+="$addr"; hosts_INFRASTRUCTURE_mac+="$mac"; hosts_INFRASTRUCTURE_name+="$Hostname"; hosts_INFRASTRUCTURE_comment+="$comment ##fingerprint==$fingerprint'"; }
                elif [[ "$comment" =~ 'TP-L' ]]; then { catagory='infrastructure'; hosts_INFRASTRUCTURE_addr+="$addr"; hosts_INFRASTRUCTURE_mac+="$mac"; hosts_INFRASTRUCTURE_name+="$Hostname"; hosts_INFRASTRUCTURE_comment+="$comment ##fingerprint==$fingerprint'"; }
                elif [[ "$mac" =~ ^'e8:de:27' ]]; then { catagory='infrastructure'; hosts_INFRASTRUCTURE_addr+="$addr"; hosts_INFRASTRUCTURE_mac+="$mac"; hosts_INFRASTRUCTURE_name+="$Hostname"; hosts_INFRASTRUCTURE_comment+="$comment ##fingerprint==$fingerprint'"; }
#                  elif [[ "$comment" =~ '' ]]; then { catagory=''; hosts__addr+="$addr"; hosts__mac+="$mac"; hosts__name+="$Hostname"; hosts__comment+="$comment ##fingerprint==$fingerprint'"; }
                else { catagory='metal'; hosts_BARE_METAL_addr+="$addr"; hosts_BARE_METAL_mac+="$mac"; hosts_BARE_METAL_name+="$Hostname"; hosts_BARE_METAL_comment+="$comment ##fingerprint==$fingerprint'"; }
            fi
            hosts_addr+="$addr"
            hosts_mac+="$mac"
            hosts_name+="$Hostname"
            hosts_comment+="$comment"
            hosts_catagory+="$catagory"

            printf "%-8s\t%s\t%s\t# %s ##fingerprint=='%s'    catagory='%s'\n" "$addr" "$mac" "${Hostname}" "$comment" "$fingerprint" "$catagory";
        fi
    done
}

Dump() {
	cat <<-EOF
		
		===========================================
		== script config state contains          ==
		===========================================
		ip='$ip'
		interface='$interface'
		mac='$mac'

		===========================================
		== new hosts file contains the following ==
		===========================================

	EOF
    cat "$temphosts"
}

Write_HOSTS_header
ArpScanHosts < <(ARP_SCAN)

Dump

#sudo arp-scan -l -I $interface
