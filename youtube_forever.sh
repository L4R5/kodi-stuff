#!/bin/bash

RUN_FILE=/tmp/youtube.dl
BIN_DIR=/home/xbmc/bin
SCRIPT=$BIN_DIR/youtube_downloader.pl



if [ -e "$RUN_FILE" ]
then
	echo "youtube downloader already running. exit."
	exit 0
fi

touch $RUN_FILE
trap "rm -rf $RUN_FILE" EXIT

$SCRIPT
