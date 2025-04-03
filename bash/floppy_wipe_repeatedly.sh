#!/bin/bash
#
# Allows for serial wiping of floppy disks in the drive specified by $1.

if [[ "$1" == "" ]] ; then
	echo "Must indicate full device name, e.g. /dev/sda"
	exit 1
fi
drive="$1"

source floppy_lib.sh "${drive}" || exit 10

while true ; do
	echo "Insert next floppy, then hit Enter"
	empty_stdin
	read temp
	floppy_wipe.sh "$1"
done
