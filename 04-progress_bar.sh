#!/bin/bash
#
# Show a progress bar
# ---------------------------------
# Redirect whiptail commands input using substitution

dd_whiptail ()
{
iso=$1
target=$2
(pv -n $iso | dd of=${target} bs=1M conv=notrunc,noerror oflag=sync) 2>&1 | whiptail --gauge " $(date) Copying files to SD in ${target}, please wait..." 10 70 0
}

tar_whiptail ()
{
file=$1
target=$2
(pv -n $file | tar xzf - -C $target ) \
2>&1 | whiptail --title "untar file" --gauge "Extracting file..." 6 50 0
}

tar_test ()
{
#Destination directory
DEST="/tmp/test.$$"
tar_whiptail ./live-build.tar.gz $DEST
}

cp_whiptail()
{
DIR=$1
DEST=$2

(
   # Get total number of files in array
   n=${#DIRS[*]};

   # set counter - it will increase every-time a file is copied to $DEST
   i=0

   #
   # Start the for loop
   #
   # read each file from $DIRS array
   # $f has filename
   for f in "${DIRS[@]}"
   do
      # calculate progress
      PCT=$(( 100*(++i)/n ))

      # update whiptail box
cat <<EOF
XXX
$PCT
Copying file "$f"...
XXX
EOF
  # copy file $f to $DEST
  /bin/cp -af $f ${DEST} &>/dev/null
   done
) | whiptail --title "Copy file" --gauge "Copying file..." 10 75 0
}

cp_test()
{
DIRS=(/bin/* /etc/* )
#DIRS="/bin/*"
# Destination directory
DEST="/tmp/test.$$"
# Create $DEST if does not exits
[ ! -d $DEST ] && mkdir -p $DEST
cp_whiptail $DIRS $DEST
/bin/rm -rf $DEST
}

whiptail_demo()
{
# set counter to 0
counter=0
(
# set infinite while loop
while :
do
cat <<EOF
XXX
$counter
copying file ( $counter%):
XXX
EOF
# increase counter by 10
(( counter+=1 ))
[ $counter -gt 101 ] && break

# delay it a specified amount of time i.e 1 sec
sleep 0.01
done
) | whiptail --title "Copy file" --gauge "yangye" 10 75 0
}

#whiptail_demo
cp_test
#tar_test

