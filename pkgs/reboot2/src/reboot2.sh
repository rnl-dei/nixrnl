#!/usr/bin/env bash
set -euo pipefail

# Check if have root privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

if [ $# -eq 0 ]; then
    echo "Usage: reboot2 <entry> [count]"
    exit 1
elif [ $# -eq 2 ]; then
    if ! [[ $2 =~ ^[0-9]+$ ]]; then
        echo "Count must be a number"
        exit 1
    fi
fi

entry=$1
count=${2:-1}

# If entry is default, reset count
if [ "${entry}" = "default" ]; then
    count=0

# Else, check if count is between 0 and 5
elif [ "$count" -lt 1 ] || [ "$count" -gt 5 ]; then
    echo "Count must be between 1 and 5"
    exit 1
fi

echo "Booting to '$entry' during $count reboots"
echo "Rebooting in 3 seconds..."
echo "Press Ctrl+C to cancel"

sleep 3

grub-editenv /boot/grub/grubenv set "entry=$entry"
grub-editenv /boot/grub/grubenv set "count=$count"
reboot
