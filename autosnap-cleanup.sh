echo "Starting Autosnap..."
#   86400 seconds = 1 day
#  604800 seconds = 1 week
# 2592000 seconds = 1 month
#31536000 seconds = 1 year (normal year)

DAILY_RETENTION=604800
WEEKLY_RETENTION=2592000
MONTHLY_RETENTION=31536000

DATE=$(date +"%Y%m%d");

BKUP2=$(/sbin/zfs list -t snapshot -o name -s creation -H | grep "$1@autosnap" );
#echo "Backup Dates:"
#echo $BKUP2

for WORKINGFULL in $BKUP2
do
	WORKING=$(echo $WORKINGFULL | grep '\d{8}' -Po);
	LAST_BKUP_TIME=$(date -d $WORKING +"%s")
	CURRENT_TIME=$(date +"%s")
	#echo "Current time seconds: $CURRENT_TIME"
	#echo "Last time seconds: $LAST_BKUP_TIME"

	let "DATE_DIFF=$CURRENT_TIME - $LAST_BKUP_TIME"
	let DATE_DIFF_DAYS=$DATE_DIFF/86400
	#echo "autosnap-$WORKING backup, $DATE_DIFF seconds or $DATE_DIFF_DAYS days old"

	#Check if it is the first monday
	if [ $(date -d $WORKING '+%A') == 'Monday' ] && [ $(date -d $WORKING '+%d') -lt 8 ] && [ $DATE_DIFF -lt $MONTHLY_RETENTION ]
	then
		echo "$WORKINGFULL will be saved for monthly snap"
	#Check if is it monday and less than weekly retention limit
	elif [ $(date -d $WORKING '+%A') == 'Monday' ] && [ $DATE_DIFF -lt $WEEKLY_RETENTION ] 
	then
		echo "$WORKINGFULL will be saved for weekly snap"
	#Check for age
	#86400 seconds = 1 day
	#604800 seconds = 1 week
	#2592000 seconds = 1 month
	elif [ $DATE_DIFF -gt $DAILY_RETENTION ]
	then
		echo "$WORKINGFULL will be deleted, age"
		zfs destroy $WORKINGFULL
		logger "Autosnap-cleanup - Deleting $WORKINGFULL, aged out"
	else
		echo "$WORKINGFULL passes"
	fi
done

