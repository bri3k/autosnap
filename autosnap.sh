#!/usr/bin/bash

FOUND=False
if [ -z $1 ]
then
	echo "Usage: autosnap <volume>"
	exit
fi

FOUND_VOLUMES=$(/sbin/zfs list -o name | grep '.*/.*')

for list in $FOUND_VOLUMES
do
	if [ $1 = $list ]
	then
		FOUND=$1
	fi
done

if [ $FOUND = "False" ]
then
	echo "No zfs volume found that matches passed parameter."
	echo "Current zfs volumes on system: $FOUND_VOLUMES"
	exit
fi
echo $FOUND


echo "Starting Autosnap..."
DATE=$(date +"%Y%m%d");

BKUP=$(/sbin/zfs list -t snapshot -o name -s creation -H | grep "$1@autosnap" | grep '\d{8}' -Po);
echo "Backup Dates:"
echo $BKUP

for WORKING in $BKUP
do
	LAST_BKUP_TIME=$(date -d $WORKING +"%s")
	CURRENT_TIME=$(date +"%s")
	#echo "Current time seconds: $CURRENT_TIME"
	#echo "Last time seconds: $LAST_BKUP_TIME"

	let "DATE_DIFF=$CURRENT_TIME - $LAST_BKUP_TIME"
	let DATE_DIFF_DAYS=$DATE_DIFF/86400
	echo "autosnap$WORKING backup, $DATE_DIFF seconds or $DATE_DIFF_DAYS days old"

	#86400 seconds = 1 day
	#604800 seconds = 1 week
	#2592000 seconds = 1 month
	if [ $DATE_DIFF -gt 86400 ]
	then
		echo "$WORKING will be deleted"
		logger "Autosnap EXAMPLE - Deleting /tank/media@autosnap-$WORKING"
	fi
done


#Create new snapshot
ANS=$(/sbin/zfs snapshot $1@autosnap-$DATE 2>&1)
RESULT=$?
if [ $RESULT -gt 0 ]
then
	echo "Error occurred: $ANS"
	logger "AUTOSNAP EXAMPLE - Snapshot creation failed:$ANS"
	exit
else
	echo "Autosnap created"
	logger "Autosnap EXAMPLE - new snapshot created $DATE - $ANS"
fi

echo "After";

/sbin/zfs list -t snapshot -o name -s creation -H;
