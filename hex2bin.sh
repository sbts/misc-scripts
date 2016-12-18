#!/bin/bash


echo -en "1234CDEF" | {
    while read -n1 Digit; do
        Bits="`echo -en "\x$Digit" | xxd -b -g1`";
        Bits="${Bits##*: }";
        echo -en "${Bits:4:4} ";
    done; 
    echo;
}

