#shell script to clean computer cache
echo -e "\n Do you want to clear page cache ? [y/n]"
read op
if [ "$op" = "y" ] 
then
	echo -e "\n clearing page cache"
	echo "`#sync; echo 1 > /proc/sys/bm/drop_caches`"
else
	echo -e "\n exiting page cache program."
	exit 1
fi

echo -e "\n Do you want to clear dentries and indoes ? [y/n]"
read op
if [ "$op" = "y" ] 
then
	echo -e "\n clearing dentries and inodes"
	echo "`#sync; echo 2 > /proc/sys/bm/drop_caches`"
else
	echo -e "\n exiting inode program."
	exit 1
fi

