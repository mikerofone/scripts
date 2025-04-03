#!/bin/bash
#
# This is a library of bash functions that is sourced by other
# floppy_*.sh scripts.
# Requires the variable 'drive' to be defined by the calling context,
# which points to the device to use.
#
# The script ensures proper permissions on 'drive' for the current user,
# and if missing, will change ownership of the requested device to the
# current user via sudo. The scripts shouldn't require running as
# super-user aside from this initial configuration step.

############### Library functions ###############

# Consumes any characters that might be in stdin one-by-one.
#
# Params: None.
# Returns: Undefined.
function empty_stdin {
	while read -r -N 1 -t 0 ; do
		read -r -N 1
	done
}

# Prompts the user to enter y or n. Any input stuck in stdin is cleared
# before.
#
# Params:
# 	$1:	The message to display. "[y,n]" is always appended.
# Returns:
#	0 if user chose y, 1 otherwise.
function ask_confirmation {
	ans=""
	while [[ "${ans}" != "n" && "${ans}" != "y" ]] ; do
		tput bel
		echo -e -n "$1 [y/n] "
		empty_stdin
		read ans
	done
	# Return 0 if answer was yes.
	[[ "${ans}" == "y" ]]
}

# First checks for non-zero size of the medium in the drive (detects
# insertion), then waits for udev to be done triggering events (drive is
# idle). Insertion of a disk fires up to four events on my machine,
# artificially slowing down the process, but waiting for all of them to
# be done ensures that there are no concurrent operations that cause
# unnecessary seeking.
#
# Params:
#	${drive} (global var):	The device to wait on.
# Returns: Undefined.
function wait_for_disk_ready {
	if ! blockdev --getsize64 "${drive}" > /dev/null 2>&1 ; then
		echo -e -n "\tWaiting for disk in ${drive} "
		while ! blockdev --getsize64 "${drive}" > /dev/null 2>&1 ; do
			echo -n "."
			sleep 1
		done
	fi
	echo -e "\tWaiting for disk to be ready..."
	udevadm settle
}

############### Permission checks ###############

if [[ "${drive}" == "" ]] ; then
	echo "SCRIPT ERROR: global variable 'drive' must be defined"
	exit 10
fi

if [ ! -e "${drive}" ] ; then
	echo "${drive} does not exist"
	exit 2
fi
if [ ! -r "${drive}" ] ; then
	ls -lh "${drive}"
	echo "${drive} is not readable, chowning it to ${USER}"
	sudo chown ${USER} ${drive} || exit 3
	ls -lh "${drive}"
fi
case "${drive}" in
	"/dev/sda")
		sgdrive="/dev/sg0" ;;
	"/dev/sdb")
		sgdrive="/dev/sg1" ;;
	"/dev/sdc")
		sgdrive="/dev/sg2" ;;
	"/dev/sdd")
		sgdrive="/dev/sg3" ;;
	*)
		echo "Unsupported drive identifier: ${drive} (cannot map to /dev/sg?)"
		exit 5 ;;
esac
	
if [ ! -w "${sgdrive}" ] ; then
	ls -lh "${sgdrive}"
	echo "${sgdrive} is not writable, chowning it to ${USER}"
	sudo chown ${USER} ${sgdrive} || exit 4
	ls -lh "${sgdrive}"
fi
