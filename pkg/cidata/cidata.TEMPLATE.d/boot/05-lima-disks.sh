#!/bin/bash

set -eux -o pipefail

test "$LIMA_CIDATA_DISKS" -gt 0 || exit 0

get_disk_var() {
	diskvarname="LIMA_CIDATA_DISK_${1}_${2}"
	eval echo \$"$diskvarname"
}

for i in $(seq 0 $((LIMA_CIDATA_DISKS - 1))); do
	DISK_NAME="$(get_disk_var "$i" "NAME")"
	DEVICE_NAME="$(get_disk_var "$i" "DEVICE")"
	FORMAT_DISK="$(get_disk_var "$i" "FORMAT")"
	FORMAT_FSTYPE="$(get_disk_var "$i" "FSTYPE")"
	FORMAT_FSARGS="$(get_disk_var "$i" "FSARGS")"

	test -n "$FORMAT_DISK" || FORMAT_DISK=true
	test -n "$FORMAT_FSTYPE" || FORMAT_FSTYPE=ext4

	# first time setup
	if [[ ! -b "/dev/disk/by-label/lima-${DISK_NAME}" ]]; then
		if $FORMAT_DISK; then
			echo 'type=linux' | sfdisk --label gpt "/dev/${DEVICE_NAME}"
			# shellcheck disable=SC2086
			mkfs.$FORMAT_FSTYPE $FORMAT_FSARGS -L "lima-${DISK_NAME}" "/dev/${DEVICE_NAME}1"
		fi
	fi

	mkdir -p "/mnt/lima-${DISK_NAME}"
	mount -t $FORMAT_FSTYPE "/dev/${DEVICE_NAME}1" "/mnt/lima-${DISK_NAME}"
done
