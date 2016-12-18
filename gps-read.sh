#!/bin/bash

GPS="${1:-/dev/ttyUSB0}";
clear;

SetGPStoNEMA() {
	echo GPS=$GPS;
	gpsctl -n $GPS;
	clear;
}

cat $GPS | while read -t10 L; do
#	if [[ 'RMC|GSA|GSV' =~ ${L:3:3} ]]; then
	if [[ 'RMC|GSA' =~ ${L:3:3} ]]; then
		#tput cup 0 0;
		#echo -n "${L:0:${#A}-1}          ";
		#tput el;
		if [[ 'RMC' =~ ${L:3:3} ]]; then
			rmc_time=`cut -d, -f2 <<<$L`;
			rmc_status=`cut -d, -f3 <<<$L`;  # A=Active V=Void
			rmc_lat=`cut -d, -f4 <<<$L`;     # 4807.038 48deg 07.038 min
			rmc_NS=`cut -d, -f5 <<<$L`;      # N=north S=south
			rmc_long=`cut -d, -f6 <<<$L`;    # 01131.123 11deg 31.123min
			rmc_EW=`cut -d, -f7 <<<$L`;      # E=east W=west
			#rmc_sog=`cut -d, -f8 <<<$L`;     # Speed over Ground in knots
			#rmc_track=`cut -d, -f9 <<<$L`;   # True track angle in degrees
			rmc_date=`cut -d, -f10 <<<$L`;   # 230394  23 march 1994
			#rmc_mag=`cut -d, -f11 <<<$L`;    # 003.1 degrees magnetic variation
			#rmc_EW=`cut -d, -f12 <<<$L`;     # Magnetic variation direction E=east W=west
			#rmc_chksum=`cut -d, -f13 <<<$L`; # *6A  checksum data, always begins with *
			tput cup 2 0;
			echo -n "${L:0:${#A}-1}";
			tput el;
			tput cup 3 0;
			echo -n "$rmc_status  $rmc_date  $rmc_time    ${rmc_date:0:2}/${rmc_date:2:2}/20${rmc_date:4:2} ${rmc_time:0:2}:${rmc_time:2:2}:${rmc_time:4:2} utc";
			tput el;
		fi
		if [[ 'GSA' =~ ${L:3:3} ]]; then
			gsa_fix=`cut -d, -f3 <<<$L`;       # 1=no fix   2=2d fix   3=3d fix
			gsa_sat[1]=`cut -d, -f4 <<<$L`;    # satellite used in fix
			gsa_sat[2]=`cut -d, -f5 <<<$L`;    # satellite used in fix
			gsa_sat[3]=`cut -d, -f6 <<<$L`;    # satellite used in fix
			gsa_sat[4]=`cut -d, -f7 <<<$L`;    # satellite used in fix
			gsa_sat[5]=`cut -d, -f8 <<<$L`;    # satellite used in fix
			gsa_sat[6]=`cut -d, -f9 <<<$L`;    # satellite used in fix
			gsa_sat[7]=`cut -d, -f10 <<<$L`;   # satellite used in fix
			gsa_sat[8]=`cut -d, -f11 <<<$L`;   # satellite used in fix
			gsa_sat[9]=`cut -d, -f12 <<<$L`;   # satellite used in fix
			gsa_sat[10]=`cut -d, -f13 <<<$L`;  # satellite used in fix
			gsa_sat[11]=`cut -d, -f14 <<<$L`;  # satellite used in fix
			gsa_sat[12]=`cut -d, -f15 <<<$L`;  # satellite used in fix
			gsa_pdop=`cut -d, -f16 <<<$L`;  # Dilution of Precision
			#gsa_hdop=`cut -d, -f17 <<<$L`;  # Horizontal Dilution of Precision
			#gsa_vdop=`cut -d, -f18 <<<$L`;  # Vertical Dilution of Precision
			#gsa_chksum=`cut -d, -f19 <<<$L`; # *6A  checksum data, always begins with *
			gsa_numsats=0;
			tput cup 7 0;
			for i in {1..12}; do
				[[ -n ${gsa_sat[$i]} ]] && (( gsa_numsats++ ));
			done
			tput cup 5 0;
			echo -n "${L:0:${#A}-1}";
			tput el;
			tput cup 6 0;
			echo -n "${gsa_numsats} satellites ${gsa_fix}d fix  $gsa_pdop Dilution of Precision";
			tput el;
		fi
		#if [[ 'GSV' =~ ${L:3:3} ]]; then
		#	tput cup 8 0;
		#	echo -n "${L:0:${#A}-1}";
		#	tput el;
		#fi
	fi
done
