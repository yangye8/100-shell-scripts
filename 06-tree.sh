#!/bin/sh

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

echo "pwd;find . | sort | sed -e '1d' -e 's/^\.//' -e 's/\/\([^/]*\)$/|--\1/' -e 's/\/[^/|]*/|  /g'"
echo "pwd;find ."
read -rp "Press any key to continue!" char
      pwd;find .
echo "pwd;find . | sort"
read -rp "Press any key to continue!" char
      pwd;find . | sort
echo "pwd;find . | sort | sed -e '1d'"
read -rp "Press any key to continue!" char
      pwd;find . | sort | sed -e '1d'
echo "pwd;find . | sort | sed -e '1d' -e 's/^\.//'" 
read -rp "Press any key to continue!" char
      pwd;find . | sort | sed -e '1d' -e 's/^\.//' 
echo "pwd;find . | sort | sed -e '1d' -e 's/^\.//' -e 's/\/\([^/]*\)$/|--\1/'"
read -rp "Press any key to continue!" char
      pwd;find . | sort | sed -e '1d' -e 's/^\.//' -e 's/\/\([^/]*\)$/|--\1/'
echo "pwd;find . | sort | sed -e '1d' -e 's/^\.//' -e 's/\/\([^/]*\)$/|--\1/' -e 's/\/[^/|]*/|  /g'"
read -rp "Press any key to continue!" char
      pwd;find . | sort | sed -e '1d' -e 's/^\.//' -e 's/\/\([^/]*\)$/|--\1/' -e 's/\/[^/|]*/|  /g'


echo "ls -R $ODIR | grep ":$" | sed -e 's/:$//' -e 's/[^-][^\/]*\//| -/g' -e 's/^/ /' -e 's/-|/ |/g' -e 's/-|/ |/g'"
read -rp "Press any key to continue!" char
echo "ls -R $ODIR"
read -rp "Press any key to continue!" char
      ls -R $ODIR
echo "ls -R $ODIR | grep ":$""
read -rp "Press any key to continue!" char
      ls -R $ODIR | grep ":$"
echo "ls -R $ODIR | grep ":$" | sed -e 's/:$//'"
read -rp "Press any key to continue!" char
      ls -R $ODIR | grep ":$" | sed -e 's/:$//'
echo "ls -R $ODIR | grep ":$" | sed -e 's/:$//' -e 's/[^-][^\/]*\//| -/g'"
read -rp "Press any key to continue!" char
      ls -R $ODIR | grep ":$" | sed -e 's/:$//' -e 's/[^-][^\/]*\//| -/g'
echo "ls -R $ODIR | grep ":$" | sed -e 's/:$//' -e 's/[^-][^\/]*\//| -/g' -e 's/^/ /'"
read -rp "Press any key to continue!" char
      ls -R $ODIR | grep ":$" | sed -e 's/:$//' -e 's/[^-][^\/]*\//| -/g' -e 's/^/ /'
echo "ls -R $ODIR | grep ":$" | sed -e 's/:$//' -e 's/[^-][^\/]*\//| -/g' -e 's/^/ /' -e 's/-|/ |/g'"
read -rp "Press any key to continue!" char
      ls -R $ODIR | grep ":$" | sed -e 's/:$//' -e 's/[^-][^\/]*\//| -/g' -e 's/^/ /' -e 's/-|/ |/g'
echo "ls -R $ODIR | grep ":$" | sed -e 's/:$//' -e 's/[^-][^\/]*\//| -/g' -e 's/^/ /' -e 's/-|/ |/g' -e 's/-|/ |/g'"
read -rp "Press any key to continue!" char
      ls -R $ODIR | grep ":$" | sed -e 's/:$//' -e 's/[^-][^\/]*\//| -/g' -e 's/^/ /' -e 's/-|/ |/g' -e 's/-|/ |/g'

echo "du -k --max-depth=1 | sort -nr "
du -k --max-depth=1 | sort -nr | awk '
     BEGIN {
        split("KB,MB,GB,TB", Units, ",");
     }
     {
        u = 1;
        while ($1 >= 1024) {
           $1 = $1 / 1024;
           u += 1
        }
        $1 = sprintf("%.1f %s", $1, Units[u]);
        print $0;
     }
    '
