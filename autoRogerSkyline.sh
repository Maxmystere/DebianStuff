#!/bin/bash
if ! command -v sudo 1>/dev/null; then
	if [ "$EUID" -ne 0 ]; then
		echo "Please run as root (su) to install sudo"
		exit
	fi
	echo "Ready to go\nUpdating Everything"
	apt update
	apt upgrade
	echo "Installing sudo and disconnecting user"
	apt install sudo
	sleep 1
	adduser max sudo
	echo "SUCCESS ! You will now be disconnected"
	sleep 1
	pkill -KILL -u max
	exit
else
	if ! [ "$EUID" -ne 0 ]; then
		echo "Please do not run as root"
		exit
	else
		echo "Working !"
	fi
fi
