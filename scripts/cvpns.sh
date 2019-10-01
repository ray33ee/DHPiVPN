#!/bin/sh

###### Script to add new VPN server to list of servers
###### List of servers is stored in /etc/vpn_lisit.conf

CHOSEN_OVPN=""

# Make sure we have the right number of command line arguments

if [ $# != 1 ]; then
	echo "Invalid number of command line arguments"
	exit 1
fi

# Download the list of IPVanish servers

wget --output-document=/tmp/ServerList-87d5b6ff65696ea676626c33201bd48d https://www.ipvanish.com/software/configs/

##################### Exclude first few entries from search

# Count the number of matching servers

COUNT=$(awk -v server="$1" 'BEGIN {count = 0} $0 ~ server { if (match($0, ".ovpn")) {count++;} } END {print count}' /tmp/ServerList-87d5b6ff65696ea676626c33201bd48d)
echo "$COUNT matches"
# If there are no matches, exit with error

if [ $COUNT == 0 ]; then
	echo "No results found. Please note: Search is case sensitive."
	exit 2
fi

# If there is a single match, use it

if [ $COUNT == 1 ]; then
	CHOSEN_OVPN=$(awk -F\" -v server="$1" '$0 ~ server { print$2 }' /tmp/ServerList-87d5b6ff65696ea676626c33201bd48d)
else
    # If there are multiple matches
	if [ $COUNT -lt 100 ]; then # If there are less than 100 matches ask user to select from list, or refine search
		LIST=$(awk -F\" -v server="$1" '$0 ~ server { if (match($2, "ovpn")) {printf("%s - ", $2); }  }' /tmp/ServerList-87d5b6ff65696ea676626c33201bd48d)
		CHOSEN_OVPN=$(whiptail --title "Menu example" --menu "Choose an option" 25 78 16 $LIST  3>&2 2>&1 1>&3)
	else
		echo "Too many results, please refine search and try again."
		exit 3
	fi
fi

if [ -z $CHOSEN_OVPN ]; then
	echo "No Server chosen, aborting..."
	exit 5
fi

# Write chosen server to a file for awk
echo "$CHOSEN_OVPN" > /tmp/ChosenServer-a69e4ed88500f9b58eaaad659970847f

# Remove the .ovpn extension
sed -i 's/.ovpn//' /tmp/ChosenServer-a69e4ed88500f9b58eaaad659970847f

# Extract the domain name from the server string
SERVER_DOMAIN=$(awk -F- '{ printf("%s-%s.ipvanish.com\n", $4, $5); }' /tmp/ChosenServer-a69e4ed88500f9b58eaaad659970847f)

echo "Domain: $SERVER_DOMAIN"

# Ping server for confirmation
ping -c 4 $SERVER_DOMAIN

read -p"Would you like to use this server? [y/N]" RESULT

# If the field is filled and not y or Y, then stop
if [ ! -z "${RESULT}" ]; then
	if [  "${RESULT}" != "y" ]  && [ "${RESULT}" != "Y" ]; then
		exit 4
	fi
fi

# Stop the outgoing server while we modify its conf file
echo "Stopping outgoing server..."
sudo service openvpn@outgoing stop

# Replace the current domain with the new one
echo "Replacing server domain in config file"
sudo sed -i "s/[a-z]*-[a-z][0-9]*.ipvanish.com/$SERVER_DOMAIN/" /etc/openvpn/outgoing.conf

# Start the server
echo "Restarting outgoing server..."
sudo service openvpn@outgoing start

# Wait for server
echo "Waiting for server to work..."
sleep 10

# Show external IP
EXTERNAL=$(dig TXT +short o-o.myaddr.l.google.com @ns1.google.com)

echo "External IP: $EXTERNAL"



