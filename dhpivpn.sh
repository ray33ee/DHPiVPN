#!/bin/sh

### Update OS ###

echo "::::: Updating OS..."

# Update and upgrade Pi

sudo apt-get update

sudo apt-get upgrade

sudo apt-get install whois # for mkpasswd

# Ask if user wishes to install screen

if (whiptail --title "Install screen" --yesno "Would you like to install screen to avoid SSH timeouts?" 8  78); then
	sudo apt-get install screen
fi

### Initial Checking ###

echo "::::: Checking conditions..."

#* Make sure script is run as root

#* Prompt user to change password if it is still the default 'raspberry'

#* use mkpasswd and /etc/shadow to see if the password for pi user is raspberry. if it is, change

if (whiptail --title "Change password" --yesno "Would you like to change the default password?" 8  78); then
	passwd
fi

### Install PiVPN ###

echo "::::: Installing PiVPN..."

# Download PiVPN installation script

wget --output-document=/tmp/PiVPNScript-ad8cc55ab4bbb7882788337140558475.sh https://install.pivpn.io/

# Before we start, warn user NOT to reboot after PiVPN completion

whiptail --title "Reboot Warning" --msgbox "At the end of the PiVPN installation, the PiVPN installation, you will be prompted to reboot. Do NOT reboot here, as you will stop the script. You will be prompted later on to reboot at a more appropriate time." 10 78

# Import temp

source /tmp/PiVPNScript-ad8cc55ab4bbb7882788337140558475.sh

# Make sure installation was successful, if not, break

if [ $? != 0 ]; then
	echo "Error ($?) installing PiVPN"
	exit 1
fi

# Ask user if they want to change hostname, if so, ask for new name

if (whiptail --title "Change hostname" --yesno "Would you like to change the hostname?" 8  78); then
    HOSTNAME=$(whiptail --inputbox "What would you line the nwe hostname to be?" 8 78 Blue --title "Change Hostname" 3>&1 1>&2 2>&3)
    if [ -z "$HOSTNAME" ]; then
        echo "Invalid hostname or user selected cancel. Aborting..."
        exit 1
    else
        sudo sh -c 'echo "$HOSTNAME" > /etc/hostname'
        sudo sed -i "/127.0.1.1/ c 127.0.1.1       $HOSTNAME" /etc/hosts
    fi
fi

# Navigate to /etc/openvpn

cd /etc/openvpn

# Download IPVanish certificate

sudo wget http://www.ipvanish.com/software/configs/ca.ipvanish.com.crt

### Edit outgoing server ###

echo ":::::Modifying server.conf..."

#* Ask user for name of server to use (default London 1)

VPN_SERVER="ipvanish-UK-London-lon-a01"

# Download server ovpn file

sudo wget "http://www.ipvanish.com/software/configs/$VPN_SERVER.ovpn"

# Rename to outgoing.conf

sudo mv "/etc/openvpn/$VPN_SERVER.ovpn" "/etc/openvpn/outgoing.conf"

# Replace dev tun in outgoing.conf

sudo sed -i 's/dev tun/dev tun-outgoing\ndev-type tun/' outgoing.conf

# Replace ca in outgoing.conf

sudo sed -i 's/ca ca.ipvanish.com.crt/ca \/etc\/openvpn\/ca.ipvanish.com.crt/' outgoing.conf

# Replace auth-user-pass in outgoing.conf

sudo sed -i 's/auth-user-pass/auth-user-pass \/etc\/openvpn\/passwd/' outgoing.conf

# Append route in outgoing.conf (using $IPv4addr and $IPv4gw from pivpn install)

echo "route $IPv4addr 255.255.255.0 $IPv4gw" >> outgoing.conf

### Create password file ###

echo ":::::Obtaining IPVanish login credentials..."

# Create /etc/openvpn/passwd

sudo touch /etc/openvpn/passwd

# Prompt user for email and password

VPN_EMAIL=$(whiptail --inputbox "Please enter your IPVanish email:" 8 78 --title "Email" 3>&1 1>&2 2>&3)

VPN_PASSWORD=$(whiptail --passwordbox "Please enter your IPVanish password:" 8 78 --title "Password" 3>&1 1>&2 2>&3)

sudo sh -c 'echo $VPN_EMAIL > /etc/openvpn/passwd'
sudo sh -c 'echo $VPN_PASSWORD >> /etc/openvpn/passwd'

# Secure file permissions

sudo chmod +600 /etc/openvpn/passwd

### Edit incoming server

echo ":::::Modifying server.conf"

# Replace dev tun in server.conf

sudo sed -i 's/dev tun/dev tun-incoming\ndev-type tun/' server.conf

### Final steps ###

echo ":::::Final steps..."

# Create and fill the file  /lib/dhcpcd/dhcpcd-hooks/40-routes

sudo touch /lib/dhcpcd/dhcpcd-hooks/40-routes

sudo sh -c 'echo "ip rule add from $IPv4addr lookup 101" >> /lib/dhcpcd/dhcpcd-hooks/40-routes'
sudo sh -c 'echo "ip route add default via $IPv4gw table 101" >> /lib/dhcpcd/dhcpcd-hooks/40-routes'

# Download startup script from github to /etc/

cd /etc/
sudo wget https://raw.githubusercontent.com/ray33ee/DHPiVPN/master/dhpivpn_startup.sh

#* call script from /etc/rc.local

# Modify /etc/default/openvpn so servers run on startup

sudo sed -i 's/#AUTOSTART="home office"/AUTOSTART="server outgoing"/' /etc/default/openvpn

# Start the servers

sudo service openvpn@outgoing start
sudo service openvpn@server start

# Reboot

if (whiptail --title "Reboot" --yesno "It is now safe to reboot. Would you like to reboot now?" 8  78); then
    sudo reboot
fi

echo "Installation complete"

exit 0