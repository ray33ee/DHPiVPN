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

* *Performance* - 
  * display percentage info as nice pie charts with actual values too. Grey out processed that are not running
* *Pi Hole* - A link to the Pi hole web interface, http://dhpivpn.io/admin
* *Admin* - Allow *dangerous* functions like
  * Stop/start/restart processes. Detect if a process is running via top/ps 

  * TO find the process ID of pihole, use something like LOOK INTO pidof COMMAND


* Calculate process CPU usage with process uptime from utime and stime via /proc/[pid]/stat, and /proc/stat total CPU times to determine the overall elapsed time in ticks.

The first command will give the totla uptime of the CPU, and the second will give the total CPU time of the process with PID 605.



# To do

* Find out if we can store IPVanish password as hash (possibly with a script from [here](https://openvpn.net/community-resources/using-alternative-authentication-methods/) or using [this](https://github.com/fionn/vpn_auth)?)
* Create program/script with basic tools like (use hyperlinks via dhpivpn.io)
  * Starting/stopping/restarting the openvpn server, openvpn outgoing, transmission daemons, noip, pihole and apache
  * Get the temperature of the system, network throughput (rx and tx, via ifstat -n -i eth0), cpu usage & pid of processes using  ps -A -f (openvpn out, openvpn in, transmission, noip, pihole and apache), memory usage
  * Change the outgoing VPN server, stop the outgoing server altogether
  * Links to pihole and transmission web interfaces
  * Show all config files (Samba, outgoing.conf, server.conf, etc.) But NOT pihole as it's done through the web interface
  * Create icon for web server
* Add script to reboot pi occasionally and update as well
* Clean up script Todos
* Add option to make device invisible over LAN? Maybe block all traffic from 192.168.0.0/16,  except router (192.168.0.1) using firewall (So the only way to connect will be via seure VPN)
* Fix external IP DDNS issue, then add noip2 to startup script 
* Add entries to the transmission and pihole web servers to link back to main web page

