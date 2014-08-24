#!/bin/bash

STATUS_FILE=/tmp/gpodder-download.status
if [ -d $STATUS_FILE ]; then
  echo "gpodder download already running. Exit..."
  exit 0
fi

mkdir $STATUS_FILE
if [ $? -eq 0 ]; then
  trap "[ -d $STATUS_FILE ] && rmdir $STATUS_FILE" 0 1 2 5 15
else
  echo "gpodder download already running. Exit..."
  exit 0
fi

cd /home/xbmc/gPodder/Downloads
gpo update
gpo download

[ -d $STATUS_FILE ] && rmdir $STATUS_FILE
