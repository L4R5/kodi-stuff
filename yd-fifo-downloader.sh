#!/bin/bash

FIFO=/tmp/yd-fifo

cd /home/xbmc/Neu
mkfifo $FIFO
exec 4<> $FIFO

while true
  do read line <$FIFO
  echo $line
  ~/bin/youtube-dl --all-subs --embed-subs --convert-subs srt "$line"
done
