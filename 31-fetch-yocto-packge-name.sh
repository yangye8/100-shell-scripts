#!/usr/bin/env bash

ls -R |grep "\.bb$" | cut -d "_" -f1 | sed "s/\.bb//" |sort -u

#while read -r f; do
##   (cd $f; find . -name "*.bb" | sed "s/^\.\///")
#    (cd $f; find . -name "*.bb" | sed "s/^\.\///" | cut -d '_' -f1 ) >> out.txt
#done < <(find ./ -name "*.bb" -print | xargs -l -i  dirname {}) 
#
#cat out.txt |sort|uniq | sed "s/.bb//" >output.txt
