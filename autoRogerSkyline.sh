#!/bin/bash
if ! command -v sudo 1>/dev/null; then
	if [ "$EUID" -ne 0 ]; then
		echo "Please run as root (su) to install sudo"
		exit
	fi
	echo "Ready to go ! Updating Everything"
	apt update
	apt upgrade
	echo "Installing sudo and disconnecting user"
	apt install sudo
	sleep 1
	adduser max sudo
	echo "SUCCESS ! You will now be disconnected"
	sleep 2
	pkill -KILL -u max
	exit
else
	if ! [ "$EUID" -ne 0 ]; then
		echo "Please do not run as root (Sudo is installed)"
		exit
	else

		echo "Ready to go ! Updating Apt"
		sudo apt update
		sudo apt upgrade
		echo "Installing vim"
		sudo apt install vim -y
		echo "We will change DHCP Last due to Bridged Adapter (For 42)"
		sleep 4
		echo "Installing ssh"
		sudo apt install ssh -y
		echo "We will now change ssh port  to 4269"
		sleep 3
		sudo sed -i 's/#Port 22/Port 4269/' /etc/ssh/sshd_config
		echo "Done ! Restarting SSH"
		sudo service sshd restart

	fi
fi
