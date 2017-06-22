#!/bin/bash

# some of the info here was taken from 
# https://www.cyberciti.biz/faq/linux-xen-vmware-kvm-intel-vt-amd-v-support/
# the rest from my own knowledge

egrep 'cpu cores|siblings' /proc/cpuinfo | head -n2 | sed -e 's/siblings/virtual cores/' -e 's/cpu cores/physical cores/' | sort;

read -st5 j mem unit < <(grep 'MemTotal' /proc/meminfo);
factor=${unit/kB/1000000};
factor=${factor/mB/1000};
echo "Total Memory: $(( mem /factor )) GB"

egrep -wo 'vmx|lm|aes' /proc/cpuinfo  \
    | sort | uniq \
    | sed -e 's/lm/64 bit cpu=Yes (&)/g' \
          -e 's/aes/Hardware encryption=Yes (&)/g' \
          -e 's/vmx/Intel hardware virtualization=Yes (&)/g' \
          -e 's/svm/AMD hardware virtualization=Yes (&)/g';

echo '============================='
echo "lscpu reports"
echo '-----------------------------'
grep 'Virtualisation:' < <(lscpu)
echo '============================='


