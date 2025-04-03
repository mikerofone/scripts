#!/bin/bash
#
# Create an image of a floppy disk in the drive specified as $1 using
# ddrescue, and if it came out clean, automatically wipe the disk.
# Intended for batch processing a large stack of disks, hence executes
# in a loop.
#
# WARNING: Use at your own risk! The script tries to detect imperfect
# ddrescue results by peeking at the mapfile, but it may not be robust
# enough to catch all corner cases. Don't blame me if you end up wiping
# a floppy without getting a clean image of it first.

if [[ "$1" == "" ]] ; then
	echo "Must indicate full device name, e.g. /dev/sda"
	exit 1
fi
drive="$1"

source floppy_lib.sh "${drive}" || exit 10

while true ; do
	ls
	echo -n "Enter name of image to create from drive ${drive}, or blank to stop: "
	# Do not empty stdin, so the next image name can be prepopulated
	# (unless unexpected prompts appeared and ate the buffer).
	read image
	logfile="${image}.log"

	if [[ "${image}" == "" ]] ; then
		echo "Exiting."
		exit 0
	fi

	if [ -e "${image}" ] ; then
		if [ -e "${logfile}" ] ; then
			if ! ask_confirmation "Logfile for image ${image} exists, continue reading?" ; then
				continue
			fi
		else
			if ! ask_confirmation "Image ${image} exists, delete and overwrite?" ; then
				continue
			fi
			rm "${image}"
		fi
	fi

	wait_for_disk_ready
	echo -e "\tCreating image ${image}..."
	ddrescue -A -M "${drive}" "${image}" "${logfile}"
	ddrescue_status=$?
	# Test if mapfile has bad areas
	incomplete_areas_count="$(egrep '^0x.* [^+0-9]$' "${logfile}" | wc -l)"

	if [[ ${ddrescue_status} != 0 || "${incomplete_areas_count}" != "0" ]] ; then
		wipe="n"
		if ask_confirmation "\t\tddrescue status ${ddrescue_status}, counted ${incomplete_areas_count} unsuccessful image parts. Wipe anyway?" ; then
			wipe="y"
		fi
	else
		wipe="y"
	fi

	if [[ "${wipe}" == "y" ]] ; then
		if floppy_wipe.sh "${drive}" ; then
			echo -e "\tFloppy in ${drive} is wiped"
		else
			echo -e "\tWipe of floppy in ${drive} failed"
		fi
	else
		echo -e "\tSkipping wipe of ${drive}"
	fi
done
