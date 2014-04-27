#!/bin/sh

INCOMING=/home/xbmc/gPodder/Downloads
DESTINATION=/media/daten1/Neu

if [ ! -d $INCOMING ]
then
	echo "$INCOMING does does not exist"
	exit 1
fi

find $INCOMING -type f ! -name "*.partial" -exec mv {} $DESTINATION \;

