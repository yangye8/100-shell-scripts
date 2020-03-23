#!/bin/bash

MYARR=(AA BB CC DD EE)
i=2
MYARR=(${MYARR[@]:0:$i} ${MYARR[@]:$i+1})
echo "${!MYARR[@]}"
echo "${MYARR[@]}"
echo ""

MYARR=(AA BB CC DD EE)
i=2
unset MYARR[$i]
echo "${!MYARR[@]}"
echo "${MYARR[@]}"
echo ""


MYARR=(AA BB CC DD EE)
i=2
unset MYARR[$i]
for ((i=0;i<${#MYARR[@]};i++)); do
    echo "MYARR[$i]=${MYARR[$i]}"
done
echo ""


MYARR=(AA BB CC DD EE)
i=2
unset MYARR[$i]
for i in ${!MYARR[@]}; do
    echo "MYARR[${i}]=${MYARR[${i}]}"
done
echo ""


MYARR=(AA BB CC DD EE)
i=2
unset MYARR[$i]
MYARR=(${MYARR[@]})
for ((i=0;i<${#MYARR[@]};i++)); do
    echo "MYARR[$i]=${MYARR[$i]}"
done
echo ""


MYARR=(AA BB CC DD EE)
unset MYARR
echo $MYARR
echo ""


