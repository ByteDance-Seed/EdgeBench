#/bin/bash

for i in `ls *.tex`
do sed -f ../mathjax.sed $i | sponge $i
done
