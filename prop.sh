#!/bin/bash

SimpleIndirectionExample() {
    cycle=(0 1 2);
    ref='cycle[i++%${#cycle[*]}]';
    echo ${!ref} ${!ref} ${!ref} ${!ref} ${!ref} ${!ref} # => 0 1 2 0 1 2
}

#PROPpre='\b'; PROPpost=''; # this one leaves cursor to right of prop
PROPpre=''; PROPpost='\b'; # this one leaves cursor over the prop. probably resulting in reverse video

PROPs=("${PROPpre}-${PROPpost}" "${PROPpre}\\\\${PROPpost}" "${PROPpre}|${PROPpost}" "${PROPpre}/${PROPpost}");

PROP='PROPs[PROPidx++%${#PROPs[*]}]';

while ! read -sn1 -t0.5; do
    echo -en "${!PROP}"
done

echo
