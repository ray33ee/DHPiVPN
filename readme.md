# DHPiVPN

Double-hop PiVPN is a project designed to automatically configure a Raspberry Pi as a double-hop VPN server. 

At its most basic, it is able to configure the inbound and outbound OpenVPN connections and setup the firewall. It is also able to install other fascilities such as Samba file sharing, Transmission, Pi-Hole and more! 

# Why DHPiVPN?

Setting up a double-hop VPN is not an easy task, especially for those new to networking and its principles. DHPiVPN aims to make this process easy. It is important to note that some aspects may need configuring as they won't apply to all cases. A list of such changes is given below

# Features

[Write paragraph summarising the features of DHPiVPN]

* List - Include a list of all featrures with more detail

# Installation

Installing DHPiVPN is quite simple. The only prerequisite is a static IP, as the installer takes care of the rest! (It is important to note that automatically configuring a static IP from DHPiVPN was deemed pointless as the user will almost certainly be installing from a headless configuration, with a static IP already configured.)

1. Install the latest (preferebly lite) version of raspbian (instructions can be found [here](https://www.raspberrypi.org/documentation/installation/installing-images/))
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

# To do

* Find out if we can store IPVanish password as hash (possibly with a script from [here](https://openvpn.net/community-resources/using-alternative-authentication-methods/) or using [this](https://github.com/fionn/vpn_auth)?)
* Create program/script with basic tools like 
  * Starting/stopping/restarting the openvpn server, openvpn outgoing anad transmission daemons
  * Get the temperature of the system, network throughput (rx and tx), cpu usage or both openvpn daemons, and transmission
  * Change the outgoing VPN server, stop the outgoing server altogether
  * Start/pause all torrents, toggle turtle mode (both an be done with [this](https://github.com/transmission/transmission/blob/master/extras/rpc-spec.txt))and provide link to transmission web interface
* Add script to reboot pi occasionally and update as well
* Suppress static ip warning in PiPVN installation if already shown in pihole installation
* Remove custom search domain prompt
* Clean up script Todos
* Finish 'features' section of readme