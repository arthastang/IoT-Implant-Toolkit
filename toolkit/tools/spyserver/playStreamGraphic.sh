#! /bin/sh

nc -lp 1338 | sox -t raw -r 16k -e signed-integer -b 16 -c 1 - -t wav - | ffplay - 
