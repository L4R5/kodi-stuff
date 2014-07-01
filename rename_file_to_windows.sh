#!/bin/bash

# renames a file, that windows can read it.
#set -x
USAGE="Usage: $0 <file1|dir1> <file2|dir2> ... <fileN|dirN>"

if [ "$#" -eq "0" ]; then
	echo "$USAGE"
	exit 1
fi

while (( "$#" )); do
	old=$1;
	new=$(echo $old | sed -e 's/:/-/g' -e 's/\?//g' -e 's/|/-/g' -e 's/\"//g')
	#echo "old: $old"
	#echo "new: $new"
	if [ "$new" != "$old" ]; then
		mv -v "$old" "$new"
		#echo "$old" "$new"
	fi
	
	shift
done

