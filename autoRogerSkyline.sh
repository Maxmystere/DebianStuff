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
	#sleep 1
	adduser max sudo
	echo "SUCCESS ! You will now be disconnected"
	#sleep 2
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
		#sleep 4

		echo "Installing ssh"
		sudo apt install ssh -y
		echo "We will now :"
		echo "change ssh port to 4269"
		echo "allow only public key"
		echo "Prevent root access from ssh"
		#sleep 3

		sudo sed -i 's/#Port 22/Port 4269/' /etc/ssh/sshd_config
		sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
		sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
		echo "Done ! Restarting SSH"
		sudo service sshd restart
		echo "Success"
		
		echo "Installing firewall"
		#sleep 1
		printf "#!/bin/sh
# /etc/init.d/firewall

case "$1" in
	start)
		# Vider les tables actuelles
		iptables -t filter -F

		# Vider les regles personnelles
		iptables -t filter -X

		# Interdire toute connexion entrante et sortante
		iptables -t filter -P INPUT DROP
		iptables -t filter -P FORWARD DROP
		iptables -t filter -P OUTPUT DROP

		# ---

		# Ne pas casser les connexions etablies
		iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
		iptables -A OUTPUT -m state --state RELATED,ESTABLISHED -j ACCEPT

		# Autoriser loopback
		iptables -t filter -A INPUT -i lo -j ACCEPT
		iptables -t filter -A OUTPUT -o lo -j ACCEPT

		# ICMP (Ping)
		iptables -t filter -A INPUT -p icmp -j ACCEPT
		iptables -t filter -A OUTPUT -p icmp -j ACCEPT

		# ---

		# SSH In/Out
		iptables -t filter -A INPUT -p tcp --dport 2222 -j ACCEPT
		iptables -t filter -A OUTPUT -p tcp --dport 2222 -j ACCEPT

		# DNS In/Out
		iptables -t filter -A OUTPUT -p tcp --dport 53 -j ACCEPT
		iptables -t filter -A OUTPUT -p udp --dport 53 -j ACCEPT
		iptables -t filter -A INPUT -p tcp --dport 53 -j ACCEPT
		iptables -t filter -A INPUT -p udp --dport 53 -j ACCEPT

		# NTP Out
		iptables -t filter -A OUTPUT -p udp --dport 123 -j ACCEPT

		# HTTP + HTTPS Out
		iptables -t filter -A OUTPUT -p tcp --dport 80 -j ACCEPT
		iptables -t filter -A OUTPUT -p tcp --dport 443 -j ACCEPT

		# HTTP + HTTPS In
		iptables -t filter -A INPUT -p tcp --dport 80 -j ACCEPT
		iptables -t filter -A INPUT -p tcp --dport 443 -j ACCEPT
		iptables -t filter -A INPUT -p tcp --dport 8443 -j ACCEPT

		# Synflood Protection
		iptables -A INPUT -p tcp --syn -m limit --limit 2/s --limit-burst 30 -j ACCEPT

		# Pingflood Protection
		iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/s -j ACCEPT

		# Portscan Protection
		iptables -A INPUT -p tcp --tcp-flags ALL NONE -m limit --limit 1/h -j ACCEPT
		iptables -A INPUT -p tcp --tcp-flags ALL ALL -m limit --limit 1/h -j ACCEPT
		;;
	stop)
		echo \"Can't really be stopped for now\"
	*)
	echo \"Usage: {start|stop}\"
	exit 1
	;;
esac

exit 0
" | sudo tee /etc/init.d/firewall
		sudo chmod +x /etc/init.d/firewall
		sudo update-rc.d firewall defaults
		sudo sh /etc/init.d/firewall
		echo "Firewall and DDOS Protection successfully installed at startup"
		#sleep 2

		echo "Adding planned task for updating apt"
		#sleep 1
		printf "#!/bin/sh

apt update
apt upgrade
" | sudo tee /etc/init.d/update_package.sh
		sudo chmod +x /etc/init.d/update_package.sh
		sudo update-rc.d update_package.sh defaults
		echo "00 04 * * 1 /etc/init.d/update_package.sh >> /var/log/update_script.log" | sudo crontab -
		echo "Done"
		#sleep 1

		echo "Installing incron and mailutils to spy /etc/crontab"
		sudo apt install mailutils -y
		sudo apt install incron -y
		echo "root" | sudo tee /etc/incron.allow
		printf "/etc/crontab IN_MODIFY echo \"crontab file has been modified\" | mail -s \"crontab Alert\" root@localhost\n" | sudo incrontab -
	fi
fi
