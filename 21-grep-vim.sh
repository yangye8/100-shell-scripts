#!/bin/bash

# grepgitvi - grep source files, interactively open vim on results
# Doesn't really have to do much with git, other than ignoring .git
#
# Copyright Yedidyah Bar David 2019
#
# SPDX-License-Identifier: Apache-2.0
#
# Requires vim and rlwrap
#
# Usage: grepgitvi <grep options> <grep/vim pattern>
#

TMPD=$(mktemp -d /tmp/grepgitvi.XXXXXX)
UNCOLORED=${TMPD}/uncolored
COLORED=${TMPD}/colored

RLHIST=${TMPD}/readline-history

[ -z "${DIRS}" ] && DIRS=.

cleanup() {
        rm -rf "${TMPD}"
}

trap cleanup 0

find ${DIRS} -iname .git -prune -o \! -iname "*.min.css*" -type f -print0 > ${TMPD}/allfiles

cat ${TMPD}/allfiles | xargs -0 grep --color=always -n -H "$@" > $COLORED
cat ${TMPD}/allfiles | xargs -0 grep -n -H "$@" > $UNCOLORED

max=`cat $UNCOLORED | wc -l`
pat="${@: -1}"

inp=''
while true; do
        echo "============================ grep results ==============================="
        cat $COLORED | nl
        echo "============================ grep results ==============================="
        prompt="Enter a number between 1 and $max or anything else to quit: "
        inp=$(rlwrap -H $RLHIST bash -c "read -p \"$prompt\" inp; echo \$inp")
        if ! echo "$inp" | grep -q '^[0-9][0-9]*$' || [ "$inp" -gt "$max" ]; then
                break
        fi

        filename=$(cat $UNCOLORED | awk -F: "NR==$inp"' {print $1}')
        linenum=$(cat $UNCOLORED | awk -F: "NR==$inp"' {print $2-1}')
        vim +:"$linenum" +"norm zz" +/"${pat}" "$filename"
done
