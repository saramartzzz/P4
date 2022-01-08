#!/bin/bash 

## \file
## \TODO This file implements a very trivial feature extraction; use it as a template for other front ends.
## \DONE
## Please, read SPTK documentation and some papers in order to implement more advanced front ends.

# Base name for temporary files
base=/tmp/$(basename $0).$$ 

# Ensure cleanup of temporary files on exit
trap cleanup EXIT
cleanup() {
   \rm -f $base.*
}

if [[ $# != 4 ]]; then
   echo "$0 mfcc_order filter_channel input.wav output.lp"
   exit 1
fi

mfcc_order=$1 #13
filter_channel=$2 #24 to 40
inputfile=$3
outputfile=$4

if [[ $UBUNTU_SPTK == 1 ]]; then
   # In case you install SPTK using debian package (apt-get)
   X2X="sptk x2x"
   FRAME="sptk frame"
   WINDOW="sptk window"
   MFCC="sptk mfcc"
else
   # or install SPTK building it from its source
   X2X="x2x"
   FRAME="frame"
   WINDOW="window"
   MFCC="mfcc"
fi

# X2X -> Convertimos enteros de 16 bits (s) a reales 4 bytes (f)
# LPC -> ventana de entrada (-l), orden del LPC (-m) y fichero de salida
# Main command for feature extration
sox $inputfile -t raw -e signed -b 16 - | $X2X +sf | $FRAME -l 240 -p 80 | $WINDOW -l 240 -L 240 |
 $MFCC -l 240 -m $mfcc_order -n $filter_channel > $base.mfcc


# Our array files need a header with the number of cols and rows:
ncol=$((mfcc_order+1)) # lpc p =>  (gain a1 a2 ... ap) 
nrow=`$X2X +fa < $base.mfcc | wc -l | perl -ne 'print $_/'$ncol', "\n";'` 

# >> escribe en el fichero definitivo de salida a continuación de lo que ya había
# Build fmatrix file by placing nrow and ncol in front, and the data after them
echo $nrow $ncol | $X2X +aI > $outputfile
cat $base.mfcc >> $outputfile

exit
