#!/bin/bash

export char

get_char()
{
    SAVEDSTTY=$(stty -g)
    stty -echo
    stty cbreak
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    stty -raw
    stty echo
    stty "$SAVEDSTTY"
}

echo 'for f in * ; do [ -d $f ] && echo $f; done'
read -rp "Press any key to continue!" char
for f in * ; do [ -d "$f" ] && echo "$f"; done
echo -e "\n\n\n"

echo "find -- * -maxdepth 0 -type d"
echo "Press any key to continue!" && char=$(get_char)
find -- * -maxdepth 0 -type d
echo -e "\n\n\n"

echo "ls -d -- */"
read -rp "Press any key to continue!" char
ls -d -- */
echo -e "\n\n\n"

echo "tree -L 1 -d ."
echo "Press any key to continue!" && char=$(get_char)
tree -L 1 -d .
