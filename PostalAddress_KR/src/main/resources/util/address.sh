#!/bin/sh
FILES=`ls $1`
for TOKEN in $FILES
do
   LINE=`sed -n '2p;3q' $TOKEN`
   DO_NAME=`echo $LINE | cut -d\| -f3`
   sed 's/,/ /g' $TOKEN | sed 's/|/,/g' > $TOKEN.cpy
   cp $TOKEN.cpy $DO_NAME.csv
done
rm *.txt *.cpy