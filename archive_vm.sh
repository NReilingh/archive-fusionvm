#!/bin/sh

if [ ! -d "$1" ]; then
	echo "Argument 1 must be a directory path to archive."
	exit 1
fi

# $1 is the path to a folder of VMs -- this will be sent directly to hdiutil
# $2 is a destination path for the disk image.

# We need an absolute path for the source.
SRCPATH=$(cd "$1"; pwd)

echo "SRCPATH is $SRCPATH"

i=0

while true; do
	# Test whether running .vmx files are inside our path.
	running=$(vmrun list | grep "$SRCPATH")

	echo "Current running VM list is $running"

	# If no VMs are running, we can continue.
	[ -z "$running" ] && break

	i=$[ $i + 1 ]
	if [ $i -gt 3 ]; then
		echo "VMs were not suspended after three tries."
		exit 1
	fi

	echo "Attempting to suspend VMs"

	xIFS=$IFS
	IFS=$'\n'
	for vmx in $running; do
		echo "Suspending $vmx"
		vmrun suspend "$vmx"
	done
	IFS=$xIFS
done

# Create a compressed read-only .dmg. HFS+ seems to be smaller than APFS.
echo "Creating disk image"
hdiutil create -srcfolder "$1" "$2" -fs HFS+

