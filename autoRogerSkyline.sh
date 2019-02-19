if ! [ -x "$(command -v sudo)" ]; then
	if [ "$EUID" -ne 0 ]
	then echo "Please run as root"
		exit
	fi
	echo "Ready to go"
else
	echo "Good"
fi
