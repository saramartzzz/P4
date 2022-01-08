#!/bin/bash 

## \file

# Base name for temporary files
base=/tmp/$(basename $0).$$ 

# Ensure cleanup of temporary files on exit
trap cleanup EXIT
cleanup() {
   \rm -f $base.*
}

if [[ $# != 4 ]]; then
   echo "$0 lpcc_order cepstrum_order input.wav output.lpcc"
   exit 1
fi

lpcc_order=$1
cepstrum_order=$2 #afegeixo
inputfile=$3
outputfile=$4

if [[ $UBUNTU_SPTK == 1 ]]; then
   # In case you install SPTK using debian package (apt-get)
   X2X="sptk x2x"
   FRAME="sptk frame"
   WINDOW="sptk window"
   LPC="sptk lpc"
   LPCC="sptk lpc2c"
else
   # or install SPTK building it from its source
   X2X="x2x"
   FRAME="frame"
   WINDOW="window"
   LPC="lpc"
   LPCC="lpc2c"
fi

# X2X -> Convertimos enteros de 16 bits (s) a reales 4 bytes (f)
# LPC -> ventana de entrada (-l), orden del LPC (-m) y fichero de salida
# Main command for feature extration
sox $inputfile -t raw -e signed -b 16 - | $X2X +sf | $FRAME -l 240 -p 80 | $WINDOW -l 240 -L 240 |
	$LPC -l 240 -m $lpcc_order | $LPCC -m $lpcc_order -M $cepstrum_order  > $base.lpcc #canvio comanda i extensió

# wc -> cuenta palabras (word count) 
# wc -l -> cuenta líneas
# Our array files need a header with the number of cols and rows:
ncol=$((lpcc_order+1)) # lpc p =>  (gain a1 a2 ... ap) 
nrow=`$X2X +fa < $base.lpcc | wc -l | perl -ne 'print $_/'$ncol', "\n";'` 

# >> escribe en el fichero definitivo de salida a continuación de lo que ya había
# Build fmatrix file by placing nrow and ncol in front, and the data after them
echo $nrow $ncol | $X2X +aI > $outputfile
cat $base.lpcc >> $outputfile

exit
