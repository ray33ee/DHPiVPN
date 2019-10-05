# DHPiVPN

Double-hop PiVPN is a project designed to automatically configure a Raspberry Pi as a double-hop VPN server. 

At its most basic, it is able to configure the inbound and outbound OpenVPN connections and setup the firewall. It is also able to install other fascilities such as Samba file sharing, Transmission, Pi-Hole and more! 

# Why DHPiVPN?

Setting up a double-hop VPN is not an easy task, especially for those new to networking and its principles. DHPiVPN aims to make this process easy, setting up all the configuration files, and even installing optional extras. It is important to note that some aspects may need configuring as they won't apply to all cases. A list of such changes is given below

# Features

DHPiVPN installs the software needed for a double hop VPN connection, but also installs extra tools. These extra tools are optional, but add many useful features, which are listed below:

* *PiVPN* - The PiVPN installation allows for incoming and outgoing connections, configuring the device as a double-hop VPN server
* *Pi-hole* - Pi-hole allows connecting clients (and local clients) to take advantage of the features of Pi hole as a DNS server
* *Samba* - Folders can be configured as Samba folders, and accessable over VPN for convenient file access
* *Transmission* - The Transmission daemon allows the Pi to run as a seedbox, with access over VPN
* *No-IP Client* - No-IP can be configured to allow Dynamic DNS for the VPN domain, and any other domains aat your home IP
* *Web Interface* - All features are controlled and monitored from a single unifying web interface 

# Installation

Installing DHPiVPN is quite simple. The only prerequisite is a static IP, as the installer takes care of the rest! (It is important to note that automatically configuring a static IP from DHPiVPN was deemed pointless as the user will almost certainly be installing from a headless configuration, with a static IP already configured.)

1. Install the latest (preferably lite) version of raspbian (instructions can be found [here](https://www.raspberrypi.org/documentation/installation/installing-images/))
2. Setup a static IP by uncommenting the example static IP configuration, and changing the network interface device (eth0), IP address and IP Gateway to your own values. (NOTE: It is best to check your router for the range of allocatable IP addresses, and choose one out of this range to avoid conflicts)
3. (Optional) To use SSH, a must for headless setups, follow the instructions found [here](https://www.raspberrypi.org/documentation/remote-access/ssh/).
4. Update and upgrade your Pi using the following commands

```sh
sudo apt-get update
sudo apt-get upgrade
```

4. Finally install DHPiVPN using the command

```sh
curl -L https://raw.githubusercontent.com/ray33ee/DHPiVPN/master/dhpivpn.sh | bash
```

# Changes

The script was specifically designed for the author. This means there are some parts that may not apply to all. While these have been kept to a minimum they do exist. A list of commands and features that may not apply to all is given below.

* In [/etc/dhpivpn_startup.sh](https://raw.githubusercontent.com/ray33ee/DHPiVPN/master/dhpivpn_startup.sh) the line

```sh
mount -t ext3 /dev/sda1 /mnt/hdd
```

is meant for mounting an external volume (such as HDD or SSD) for large storage. If you don't have this or don't want it, you should remove it. However if you are using an external volume, this command is useful as it automatically mounts the volume on startup. You may wish to change sda1 to your partition name.

* In [settings.json](https://raw.githubusercontent.com/ray33ee/DHPiVPN/master/settings.json) several changes have been made from the original settings.json, but the incomplete-dir /mnt/hdd/incomplete and the download-dir /mnt/hdd/downloads both point to the external volume mentioned above.

# Web interface

[Descripion of web interface]

[List of web interface features] 

# To do

## Web server

* Improve/create menu, title, logo and icon. 
* Improve look of web pages, with grey background and white boxes around each widget
* Password protect web server
* Create admin page that can change dhpivpn, transmission and pihole passwords
* Create speed page that shows bandwidth details and
* Create VPN page used so change outgoing vpn server and stop server altogether 
* Centralise JS, CSS and PHP code used accross multiple files
* Add temperature reading to main page
* Allow user to change outgoing vpn server (based on a preconfigured list. more can be added to the list via cvpns.sh)
* Modify the transmission and pihole web interfaces to add links to dhpivpn web interface
* Stop charts resizing (this happens when the percentages in the legend come and go, and change the available size for the graph)
* OPTIONAL: Add setup page that modifies key fields in daemon config files (download limits in transmission, turtle download speed in transmission, etc.)
* OPTIONAL: Add public/private key authentication to SSH

## Scripts

* Add installation of web server tools to script (installing vnstat, adding www-data to visudo, installing speedtest-cli)
* Add script to periodically update, upgrade and reboot Pi. Update pihole, transmission, and anything else that can be manually updated
* Add script to update noip2 by shutting down outgoing server. TO do this, the outbound server must be disabled to expose the modems IP. TO ensure security, the inbound server and transmission must be stopped to prevent users connecting while the VPN server is down. (First stop the incoming server and transmission, then stop outbound server. This will expose your Pi to the internet directly, and expose its external address. Verify IP has changed, and turn on noip for long enough to update IP. then turn noip off, the outbound server on, followed by the incoming server and transmission. Check IP is the IP of the chosen vpn server.)
* Complete all todos in dhpivpn (marked with an '\*')
* Download web server from github during installation

## Samba

* Add passwords to \\\\pivpn 

## PiVPN

* Store IPVanish password as hash/ use public-private key
