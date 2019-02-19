#!/bin/bash
if ! command -v sudo 1>/dev/null; then
	if [ "$EUID" -ne 0 ]; then
		echo "Please run as root"
		exit
	fi
	echo "Ready to go"
else
	echo "Good"
fi
