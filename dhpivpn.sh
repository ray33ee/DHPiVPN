#!/bin/sh

SAMBA_TYPE="partial"
PI_HOLE="off"

### Update OS ###

#* Check for whiptail, install if not found

#* Check for whois, install if not found

### Make sure user has secure password

sudo apt-get -y install whois

# Use the seed and the default password to generate a hash for the default password, 'raspberry'

DEFAULT_HASH=$(sudo awk -F: '/[$]/{ split($2, hash, "$");  seed = hash[3]; system("mkpasswd --method=SHA-512 --salt=" seed " raspberry") }' /etc/shadow)

# Take the hash from the user profile in shadow

ACTUAL_HASH=$(sudo awk -F: '/[$]/{ print $2 }' /etc/shadow)

# If the two hashes are the same, the user still has the default password

if [ $DEFAULT_HASH == $ACTUAL_HASH ]; then
    if (whiptail --title "Change Password" --yesno "The installer has detected you are using the default password shipped with the Pi. Since this Pi will be exposed to the internet, this is not a good idea. Would you like to change the password now?" 10  78); then
        passwd
    fi

    # Check return value of passwd to inform user of success/fail

    EXIT_VALUE=$?

    if [ $EXIT_VALUE != 0 ]; then
        whiptail --title "Password unchanged" --msgbox "Password was not changed. Passwd exited with error code $EXIT_VALUE." 8 78
    else
        whiptail --title "Password changed" --msgbox "Password was successfully changed." 8 78
    fi
fi




### Install Pi-Hole first (don't do it last, just don't. If you do, the Pi will stop networking)

if (whiptail --title "Pi-Hole" --yesno "Would you like to install Pi-Hole?" 8  78); then
    echo "::::: Installing Pi-Hole..."
    sudo sh -c 'curl -sSL https://install.pi-hole.net/ | bash'

    sync

    # Enable 'Listen on all interfaces', to allow Pi hole to work over VPN

    pihole -a interface local

    # Copy settings over
    wget --output-document=/tmp/PiHoleAdlist-bfe63bd5739d2ab82a20f96e44a0eb9a https://raw.githubusercontent.com/ray33ee/DHPiVPN/master/pihole/adlists.list
    wget --output-document=/tmp/PiHoleWhitelist-dc20dd1f615c3fd188c708858bb6d649 https://raw.githubusercontent.com/ray33ee/DHPiVPN/master/pihole/whitelist.txt

    sudo mv /tmp/PiHoleAdlist-bfe63bd5739d2ab82a20f96e44a0eb9a /etc/pihole/adlists.list
    sudo mv /tmp/PiHoleWhitelist-dc20dd1f615c3fd188c708858bb6d649 /etc/pihole/whitelist.txt

    # Restart DNS server
    pihole restartdns

    # Restart gravity - responsible for resolving the whitelist entries
    pihole -g

    
    PI_HOLE="on"
fi

### Install PiVPN ###

echo "::::: Installing PiVPN..."

# Download PiVPN installation script

echo "::::: Obtaining PiVPN installer..."
wget --output-document=/tmp/PiVPNInstaller-ad8cc55ab4bbb7882788337140558475.sh https://install.pivpn.io/

# Remove the prompt to setup custom search domain

echo "::::: Remove CSD prompt from install.sh..."
awk 'BEGIN {findCount = 0} { if (match($0, "setCustomDomain")) { if (findCount == 1) { print ":" } else { print } findCount++ } else { print } }' /tmp/PiVPNInstaller-ad8cc55ab4bbb7882788337140558475.sh > /tmp/PiVPNInstaller-f014b94c35268c600ab22ef3e885b54f.sh

# Before we start, remove the code that prompts the user to reboot

echo "::::: Remove prompt from install.sh..."
awk 'BEGIN {findCount = 0} { if (match($0, "displayFinalMessage")) { if (findCount == 1) { print ":" } else { print } findCount++ } else { print } }' /tmp/PiVPNInstaller-f014b94c35268c600ab22ef3e885b54f.sh > /tmp/PiVPNInstaller-off-9ae73c65f418e6f79ceb4f0e4a4b98d5.sh

# If we are using Pi Hole, don't ask for DNS server, as we will use 10.8.0.1

echo $PI_HOLE

if [ $PI_HOLE == "on" ]; then
    echo "::::: Remove DNS prompt..."
    awk 'BEGIN {findCount = 0} { if (match($0, "setClientDNS")) { if (findCount == 1) { print ":" } else { print } findCount++ } else { print } }' /tmp/PiVPNInstaller-off-9ae73c65f418e6f79ceb4f0e4a4b98d5.sh > /tmp/PiVPNInstaller-on-9ae73c65f418e6f79ceb4f0e4a4b98d5.sh
    echo "::::: Remove DHCP conflict prompt..."
    sudo sed -i "/FYI: IP Conflict/d" /tmp/PiVPNInstaller-on-9ae73c65f418e6f79ceb4f0e4a4b98d5.sh
    sudo sed -i "/If you are worried/d" /tmp/PiVPNInstaller-on-9ae73c65f418e6f79ceb4f0e4a4b98d5.sh
    sudo sed -i '/It is also possible to/ c :'  /tmp/PiVPNInstaller-on-9ae73c65f418e6f79ceb4f0e4a4b98d5.sh
fi

# Install Pivpn

echo "::::: Execute installer..."
source /tmp/PiVPNInstaller-${PI_HOLE}-9ae73c65f418e6f79ceb4f0e4a4b98d5.sh

# Make sure installation was successful, if not, break

if [ $? != 0 ]; then
	echo "Error ($?) installing PiVPN"
	exit 1
fi

# Ask user if they want to change hostname, if so, ask for new name

if (whiptail --title "Change hostname" --yesno "Would you like to change the hostname?" 8  78); then
    HOSTNAME=$(whiptail --inputbox "What would you line the new hostname to be?" 8 78 $HOSTNAME --title "Change Hostname" 3>&1 1>&2 2>&3)
    if [ -z "$HOSTNAME" ]; then
        echo "Invalid hostname or user selected cancel. Aborting..."
        exit 1
    else
        sudo sh -c "echo \"$HOSTNAME\" > /etc/hostname"
        sudo sed -i "/127.0.1.1/ c 127.0.1.1       $HOSTNAME" /etc/hosts
        sudo sh -c 'echo "10.8.0.1        dhpivpn.io" >> /etc/hosts'
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

#* Ask user to confirm password

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

# If user installed Pi-Hole, change the DNS to 10.8.0.1

if [ $PI_HOLE == "on" ]; then
    # Remove all current DNS servers
    echo "::::: Edit DNS in server.conf..."
    sudo sed -i '/push "dhcp-option DNS/d' server.conf
    sudo sh -c 'echo "push \"dhcp-option DNS 10.8.0.1\"" >> server.conf'
fi

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
sudo wget https://raw.githubusercontent.com/ray33ee/DHPiVPN/master/scripts/dhpivpn_startup.sh

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

### Install No-IP DDNS client

if (whiptail --title "Dynamic DNS" --yesno "Would you like to install No-IP's Dynamic Update Client?" 8  78); then
    echo "::::: Fetching No-IP software..."
    cd /tmp
    wget --output-document=NoIPDDNSInstaller-6495fa7db8769024ebd3b653856bd2bb.tar.gz https://www.noip.com/client/linux/noip-duc-linux.tar.gz
    echo "::::: Unzipping archive..."
    tar vzxf NoIPDDNSInstaller-6495fa7db8769024ebd3b653856bd2bb.tar.gz
    cd noip-*
    echo "::::: Installing No-IP Client.."
    sudo make
    sudo make install
    echo "::::: Running client..."
    sudo /usr/local/bin/noip2
    #echo "::::: Adding client to startup script..."

fi



### Install Transmissinon

if (whiptail --title "Transmission" --yesno "Would you like to install Transmission (transmission-daemon)?" 8  78); then
    echo "::::: Installing transmission-daemon..."
    sudo apt-get -y install transmission-daemon
    echo "::::: Stopping daemon..."
    sudo systemctl stop transmission-daemon
    echo "::::: Creating hdd directory..."
    sudo mkdir /mnt/hdd
    echo "::::: Changing settings.json..."
    cd /etc/transmission-daemon/
    sudo rm settings.json
    sudo wget https://raw.githubusercontent.com/ray33ee/DHPiVPN/master/transmission/settings.json
    # Ask user for username (default 'transmission') and password

    TRANSMISSION_USERNAME=$(whiptail --inputbox "Please chose the username for transmission:" 8 78 transmission --title "Username" 3>&1 1>&2 2>&3)

    TRANSMISSION_PASSWORD1=$(whiptail --passwordbox "Please enter the transmission password:" 8 78 --title "Password" 3>&1 1>&2 2>&3)

    #* Ask user to confirm password

    # Add username and password to settings.json

    sudo sed -i "s/\"rpc-username\": \"\"/\"rpc-username\": \"$TRANSMISSION_USERNAME\"/" settings.json
    sudo sed -i "s/\"rpc-password\": \"\"/\"rpc-password\": \"$TRANSMISSION_PASSWORD1\"/" settings.json

    #  user for password second time, then verify

    echo "::::: Starting daemon..."
    sudo systemctl start transmission-daemon
    SAMBA_TYPE="full"
fi

### Install Samba

if (whiptail --title "Samba file share" --yesno "Would you like to install Samba file share?" 8  78); then
    echo "::::: Installing Samba..."
    sudo apt-get -y install samba samba-common-bin
    echo "::::: Changing smb.conf..."
    cd /etc/samba/
    sudo rm smb.conf
    sudo wget https://raw.githubusercontent.com/ray33ee/DHPiVPN/master/samba/${SAMBA_TYPE}_smb.conf
    sudo mv ${SAMBA_TYPE}_smb.conf smb.conf
    echo "::::: Adding Samba user and group..."
    #sudo addgroup smbgrp
    #sudo useradd smbusr -G smbgrp
    #whiptail --title "Connection" --msgbox "You will now be prompted for a password for Samba filesharing." 8 78
    #sudo smbpasswd -a smbusr    
    sudo chmod 775 /home/pi/ovpns
    echo "::::: Restarting daemon..."
    sudo /etc/init.d/smbd restart
    echo "::::: Changing permissions of ovpns..."
    #sudo chown root:smbgrp /home/pi/ovpns
fi

### Install Apache & php

if (whiptail --title "Apache web server" --yesno "Would you like to install Apache (apache2)?" 8  78); then
    echo "::::: Installing Apache..."
    sudo apt-get install apache2 -y
    echo "::::: Installing PHP..."
    sudo apt-get install php libapache2-mod-php -y
    echo "::::: Installing vnStat..."
    sudo apt-get install vnstat
    #* Download web pages from github
fi

echo "::::: Installation complete"

if (whiptail --title "Reboot" --yesno "The installation is complete, and it is now safe to reboot. Would you like to reboot now?" 8  78); then
    whiptail --title "Rebooting" --msgbox "Your device will now reboot..." 8 78
    echo "::::: Rebooting..."
    sudo reboot
    sleep 4
fi  

exit 0