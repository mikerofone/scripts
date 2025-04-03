#!/bin/bash
#
# Waits for a floppy to be present in the device given as $1, then
# formats it and creates an empty MS-DOS filesystem.
#
# MAKE SURE YOU USE THE RIGHT DRIVE! The script does not try to prevent
# you from mistakes.

if [[ "$1" == "" ]] ; then
	echo "Must indicate full device name, e.g. /dev/sda"
	exit 1
fi
drive="$1"

source floppy_lib.sh "${drive}" || exit 10

wait_for_disk_ready
echo -e "\tWiping ${drive}"
while ! ( ufiformat -V "${drive}" && mkdosfs -F 12 -M 0xf0 "${drive}" ) ; do
	if ! ask_confirmation "\tWipe failed, disk write protected? Try again?" ; then
		exit 1
	fi
	wait_for_disk_ready
done
