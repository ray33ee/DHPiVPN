#!/bin/sh

SAMBA_TYPE="partial"

### Update OS ###

# Update and upgrade Pi

#echo "::::: Updating OS..."
#sudo apt-get update


#echo "::::: Upgrading OS..."
#sudo apt-get upgrade

# Wait a few seconds to catch up
#sudo sleep 4

# Wait a few seconds to catch up
#sudo sleep 4

### Install Pi-Hole first (don't do it last, just don't. If you do, the Pi will stop networking)

if (whiptail --title "Pi-Hole" --yesno "Would you like to install Pi-Hole?" 8  78); then
    echo "::::: Installing Pi-Hole..."
    sudo sh -c 'curl -sSL https://install.pi-hole.net/ | bash'
    #* Change DNS IP in server.conf to 10.8.0.1
    #* Tell user to select 'Listen on all interfaces' in Settings, DNS.
    #* Can we change Pi-Hole settings via config file?
fi

### Install PiVPN ###

echo "::::: Installing PiVPN..."

# Install Pi-Hole first (don't do it last, just don't. If you do, the Pi will stop networking)

if (whiptail --title "Pi-Hole" --yesno "Would you like to install Pi-Hole?" 8  78); then
    echo "::::: Installing Pi-Hole..."
    sudo sh -c 'curl -sSL https://install.pi-hole.net/ | bash'
    #* Change DNS IP in server.conf to 10.8.0.1
    #* Tell user to select 'Listen on all interfaces' in Settings, DNS.
    #* Can we change Pi-Hole settings via config file?
fi

# Download PiVPN installation script

echo "::::: Obtaining PiVPN installer..."
wget --output-document=/tmp/PiVPNInstaller-ad8cc55ab4bbb7882788337140558475.sh https://install.pivpn.io/

# Before we start, remove the code that prompts the user to reboot

awk 'BEGIN {findCount = 0} { if (match($0, "displayFinalMessage")) { if (findCount == 1) { print ":" } else { print } findCount++ } else { print } }' /tmp/PiVPNInstaller-ad8cc55ab4bbb7882788337140558475.sh > /tmp/PiVPNInstaller-9ae73c65f418e6f79ceb4f0e4a4b98d5.sh

# Import installation script

echo "::::: Execute installer..."
source /tmp/PiVPNInstaller-9ae73c65f418e6f79ceb4f0e4a4b98d5.sh

# Make sure installation was successful, if not, break

if [ $? != 0 ]; then
	echo "Error ($?) installing PiVPN"
	exit 1
fi

echo "Chosen IP: $IPv4addr"
echo "Chosen GW: $IPv4gw"

# Ask user if they want to change hostname, if so, ask for new name

if (whiptail --title "Change hostname" --yesno "Would you like to change the hostname?" 8  78); then
    HOSTNAME=$(whiptail --inputbox "What would you line the new hostname to be?" 8 78 $HOSTNAME --title "Change Hostname" 3>&1 1>&2 2>&3)
    if [ -z "$HOSTNAME" ]; then
        echo "Invalid hostname or user selected cancel. Aborting..."
        exit 1
    else
        sudo sh -c "echo \"$HOSTNAME\" > /etc/hostname"
        sudo sed -i "/127.0.1.1/ c 127.0.1.1       $HOSTNAME" /etc/hosts
    fi
fi

# Navigate to /etc/openvpn

cd /etc/openvpn

# Download IPVanish certificate

echo "::::: Get certificate..."
sudo wget http://www.ipvanish.com/software/configs/ca.ipvanish.com.crt

### Edit outgoing server ###

echo ":::::Modifying server.conf..."

#* Ask user for name of server to use (default London 1)

VPN_SERVER="ipvanish-UK-London-lon-a01"

# Download server ovpn file


echo "::::: Get server file..."
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

sudo sh -c "echo \"route $IPv4addr 255.255.255.0 $IPv4gw\" >> outgoing.conf"

### Create password file ###

echo ":::::Obtaining IPVanish login credentials..."

# Create /etc/openvpn/passwd


echo "::::: Create password file..."
sudo touch /etc/openvpn/passwd

# Prompt user for email and password

VPN_EMAIL=$(whiptail --inputbox "Please enter your IPVanish email:" 8 78 --title "Email" 3>&1 1>&2 2>&3)

VPN_PASSWORD=$(whiptail --passwordbox "Please enter your IPVanish password:" 8 78 --title "Password" 3>&1 1>&2 2>&3)


echo "::::: Writing credentials..."
sudo sh -c "echo $VPN_EMAIL > /etc/openvpn/passwd"
sudo sh -c "echo $VPN_PASSWORD >> /etc/openvpn/passwd"

# Secure file permissions


echo "::::: Update permissions..."
sudo chmod +600 /etc/openvpn/passwd

### Edit incoming server

echo ":::::Modifying server.conf"

# Replace dev tun in server.conf

sudo sed -i 's/dev tun/dev tun-incoming\ndev-type tun/' server.conf

### Final steps ###

echo ":::::Final steps..."

# Create and fill the file  /lib/dhcpcd/dhcpcd-hooks/40-routes


echo "::::: Updating routing tables..."
sudo touch /lib/dhcpcd/dhcpcd-hooks/40-routes

sudo sh -c "echo \"ip rule add from $IPv4addr lookup 101\" >> /lib/dhcpcd/dhcpcd-hooks/40-routes"
sudo sh -c "echo \"ip route add default via $IPv4gw table 101\" >> /lib/dhcpcd/dhcpcd-hooks/40-routes"

# Download startup script from github to /etc/


echo "::::: Downloading startup script..."
cd /etc/
sudo wget https://raw.githubusercontent.com/ray33ee/DHPiVPN/master/dhpivpn_startup.sh

# Call script from /etc/rc.local


echo "::::: Call script from rc.local..."
sudo sed -i '7,$ s/exit 0//' /etc/rc.local # remove exit 0

sudo sh -c 'echo bash /etc/dhpivpn_startup.sh >> /etc/rc.local' # Add script

sudo sh -c 'echo "exit 0" >> /etc/rc.local' 

# Modify /etc/default/openvpn so servers run on startup

sudo sed -i 's/#AUTOSTART="home office"/AUTOSTART="server outgoing"/' /etc/default/openvpn

# Start the servers


echo "::::: Start servers..."
sudo service openvpn@outgoing start
sudo service openvpn@server start

# Wait 4 seconds for the daemons to ready up
sudo sleep 4

# Reboot

if (whiptail --title "Continue" --yesno "Double hop VPN is now configured. Would you like to install optional extras?" 8  78); then
    :
else
    if (whiptail --title "Reboot" --yesno "The installation is complete, and it is now safe to reboot. Would you like to reboot now?" 8  78); then
        whiptail --title "Rebooting" --msgbox "Your device will now reboot..." 8 78
        sudo reboot
        sudo sleep 4
    else
        exit 0
    fi
fi

### Install Transmissinon

if (whiptail --title "Transmission" --yesno "Would you like to install Transmission (transmission-daemon)?" 8  78); then
    echo "::::: Installing transmission-daemon..."
    sudo apt-get install transmission-daemon
    echo "::::: Stopping daemon..."
    sudo systemctl stop transmission-daemon
    echo "::::: Creating hdd directory..."
    sudo mkdir /mnt/hdd
    echo "::::: Changing settings.json..."
    cd /etc/transmission-daemon/
    sudo rm settings.json
    sudo wget https://raw.githubusercontent.com/ray33ee/DHPiVPN/master/settings.json
    #* Ask user for username (default 'transmission') and password
    echo "::::: Starting daemon..."
    sudo systemctl start transmission-daemon
    SAMBA_TYPE="full"
fi

### Install Samba

if (whiptail --title "Samba file share" --yesno "Would you like to install Samba file share?" 8  78); then
    echo "::::: Installing Samba..."
    sudo apt-get install samba samba-common-bin
    echo "::::: Changing smb.conf..."
    cd /etc/samba/
    sudo rm smb.conf
    sudo wget https://raw.githubusercontent.com/ray33ee/DHPiVPN/master/$SAMBA_TYPE_smb.conf
    sudo mv $SAMBA_TYPE_smb.conf smb.conf
    #* If transmission is not installed, remove the 'incomplete' and 'torrents' entries 
    echo "::::: Restarting daemon..."
    sudo /etc/init.d/smbd restart
    echo "::::: Changing permissions of ovpns..."
    sudo chmod 775 /home/pi/ovpns
fi

### Install Apache & php

if (whiptail --title "Apache web server" --yesno "Would you like to install Apache (apache2)?" 8  78); then
    echo "::::: Installing Apache..."
    sudo apt-get install apache2 -y
    sudo apt-get install php libapache2-mod-php -y
    #* Download web pages from github
fi

echo "::::: Installation complete"

if (whiptail --title "Reboot" --yesno "The installation is complete, and it is now safe to reboot. Would you like to reboot now?" 8  78); then
    whiptail --title "Rebooting" --msgbox "Your device will now reboot..." 8 78
    sudo reboot
    sleep 4
fi  

exit 0