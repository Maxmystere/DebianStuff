#!/bin/bash
if ! command -v sudo 1>/dev/null; then
	if [ "$EUID" -ne 0 ]; then
		echo -e "\e[31mPlease run as root (su) to install sudo\e[0m"
		exit
	fi
	echo -e "\e[33mReady to go ! Updating Everything\e[0m"
	apt update
	apt upgrade
	echo -e "\e[33mInstalling sudo and disconnecting user\e[0m"
	apt install sudo
	#sleep 1
	adduser max sudo
	echo -e "\e[33mSUCCESS ! You will now be disconnected\e[0m"
	#sleep 2
	pkill -KILL -u max
	exit
else
	if ! [ "$EUID" -ne 0 ]; then
		echo -e "\e[31mPlease do not run as root (Sudo is installed)\e[0m"
		exit
	else

		echo -e "\e[33mReady to go ! Updating Apt\e[0m"
		sudo apt update
		sudo apt upgrade
		echo -e "\e[33mInstalling vim\e[0m"
		sudo apt install vim -y
		echo -e "\e[33mWe will change DHCP Last due to Bridged Adapter (For 42)\e[0m"
		#sleep 4

		echo -e "\e[33mInstalling ssh\e[0m"
		sudo apt install ssh -y
		echo -e "\e[33mWe will now :"
		echo -e "\e[33mchange ssh port to 4269\e[0m"
		echo -e "\e[33mallow only public key\e[0m"
		echo -e "\e[33mPrevent root access from ssh\e[0m"
		#sleep 3

		sudo sed -i 's/#Port 22/Port 4269/' /etc/ssh/sshd_config
		sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
		sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
		echo -e "\e[33mDone ! Restarting SSH\e[0m"
		sudo service sshd restart
		echo -e "\e[33mSuccess\e[0m"
		
		echo -e "\e[33mInstalling firewall\e[0m"
		sudo mkdir /etc/startup
		#sleep 1
		printf "#!/bin/sh
# /etc/startup/firewall

# Vider les tables actuelles
sudo iptables -t filter -F

# Vider les regles personnelles
sudo iptables -t filter -X

# Interdire toute connexion entrante et sortante
sudo iptables -t filter -P INPUT DROP
sudo iptables -t filter -P FORWARD DROP
sudo iptables -t filter -P OUTPUT DROP

# ---

# Ne pas casser les connexions etablies
sudo iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A OUTPUT -m state --state RELATED,ESTABLISHED -j ACCEPT

# Autoriser loopback
sudo iptables -t filter -A INPUT -i lo -j ACCEPT
sudo iptables -t filter -A OUTPUT -o lo -j ACCEPT

# ICMP (Ping)
sudo iptables -t filter -A INPUT -p icmp -j ACCEPT
sudo iptables -t filter -A OUTPUT -p icmp -j ACCEPT

# ---

# SSH In/Out
sudo iptables -t filter -A INPUT -p tcp --dport 2222 -j ACCEPT
sudo iptables -t filter -A OUTPUT -p tcp --dport 2222 -j ACCEPT

# DNS In/Out
sudo iptables -t filter -A OUTPUT -p tcp --dport 53 -j ACCEPT
sudo iptables -t filter -A OUTPUT -p udp --dport 53 -j ACCEPT
sudo iptables -t filter -A INPUT -p tcp --dport 53 -j ACCEPT
sudo iptables -t filter -A INPUT -p udp --dport 53 -j ACCEPT

# NTP Out
sudo iptables -t filter -A OUTPUT -p udp --dport 123 -j ACCEPT

# HTTP + HTTPS Out
sudo iptables -t filter -A OUTPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -t filter -A OUTPUT -p tcp --dport 443 -j ACCEPT

# HTTP + HTTPS In
sudo iptables -t filter -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -t filter -A INPUT -p tcp --dport 443 -j ACCEPT
sudo iptables -t filter -A INPUT -p tcp --dport 8443 -j ACCEPT

# Synflood Protection
sudo iptables -A INPUT -p tcp --syn -m limit --limit 2/s --limit-burst 30 -j ACCEPT

# Pingflood Protection
sudo iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/s -j ACCEPT

# Portscan Protection
sudo iptables -A INPUT -p tcp --tcp-flags ALL NONE -m limit --limit 1/h -j ACCEPT
sudo iptables -A INPUT -p tcp --tcp-flags ALL ALL -m limit --limit 1/h -j ACCEPT

exit 0
" | sudo tee /etc/startup/firewall
		sudo chmod +x /etc/startup/firewall
		#sudo update-rc.d firewall defaults
		sudo sh /etc/startup/firewall
		echo -e "\e[33mFirewall and DDOS Protection successfully installed at startup\e[0m"
		#sleep 2

		echo -e "\e[33mAdding planned task for updating apt\e[0m"
		#sleep 1
		printf "#!/bin/sh
# /etc/startup/update_package.sh

sudo apt update
sudo apt upgrade

exit 0
" | sudo tee /etc/startup/update_package.sh
		sudo chmod +x /etc/startup/update_package.sh
		#sudo update-rc.d update_package.sh defaults
		echo "00 04 * * 1 /etc/startup/update_package.sh >> /var/log/update_script.log
@reboot /etc/startup/firewall
@reboot /etc/startup/update_package.sh >> /var/log/update_script.log" | sudo crontab -
		echo -e "\e[33mDone\e[0m"
		#sleep 1

		echo -e "\e[33mInstalling incron and mailutils to spy /etc/crontab\e[0m"
		sudo apt install mailutils -y
		sudo apt install incron -y
		echo "root" | sudo tee /etc/incron.allow
		printf "/etc/crontab IN_MODIFY echo \"crontab file has been modified\" | mail -s \"crontab Alert\" root@localhost\n" | sudo incrontab -

		echo -e "\e[33mInstalling apache\e[0m"
		sudo apt install apache2 -y
		sudo apt install openssl -y
		sudo mkdir /etc/apache2/ssl
		echo -e "\e[33mYou now have to :
	- Remove DHCP
	- Add apache Website\e[0m"
		# https://wiki.debian.org/fr/NetworkConfiguration
		# https://technique.arscenic.org/lamp-linux-apache-mysql-php/apache-le-serveur-http/modules-complementaires/article/installer-et-configurer-le-module-ssl-pour-apache2
	fi
fi
