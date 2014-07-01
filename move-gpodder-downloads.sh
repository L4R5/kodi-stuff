#!/bin/sh

INCOMING=/home/xbmc/gPodder/Downloads
DESTINATION=/media/daten1/Neu

# check if destination disk is in standby mode
# do not move files until disk is active again or download directory
# disk becomes full

if [ ! -d $INCOMING ]
then
	echo "$INCOMING does does not exist"
	exit 1
fi

find $INCOMING -type f ! -name "*.partial" -exec mv {} $DESTINATION \;
# sudo hdparm -C $(df $DESTINATION | tail -1 | awk '{print $1}') | grep standby
