#!/bin/bash

set -e

Git_update()
{
changed=0
git remote update && git status -uno | grep -q 'Your branch is behind' && changed=1
if [ $changed = 1 ]; then
	git pull
	echo "Updated successfully";
else
	echo "Up-to-date"
fi
}

Read_ans()
{
echo -n "$@    "
read ans
while [[ $ans != "Y" && $ans != "y" && $ans != "N" && $ans != "n" ]] 
do
	echo -n "$@    "
	read ans 
done
if [ $ans = 'N' -o $ans = 'n' ]; then
	Echo_done && exit 0
fi
}

Get_dist_name()
{
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
elif type lsb_release >/dev/null 2>&1; then
    OS=$(lsb_release -si)
    VER=$(lsb_release -sr)
elif [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    OS=$DISTRIB_ID
    VER=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
    OS=Debian
    VER=$(cat /etc/debian_version)
else
    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    OS=$(uname -s)
    VER=$(uname -r)
fi
	echo $OS $VER;
}
