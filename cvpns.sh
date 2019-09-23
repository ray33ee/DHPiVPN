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
echo $COUNT
# If there are no matches, exit with error

if [ $COUNT == 0 ]; then
        echo "No results found."
        exit 2
fi

# If there is a single match, use it

if [ $COUNT == 1 ]; then
        CHOSEN_OVPN=$(awk -F\" -v server="$1" '$0 ~ server { print$2 }' /tmp/ServerList-87d5b6ff65696ea676626c33201bd48d)
else
    # If there are multiple matches
	if [ $COUNT -lt 100 ]; then # If there are less than 100 matches ask user to select from list, or refine search
	        LIST=$(awk -F\" -v server="$1" '$0 ~ server { if (match($2, "ovpn")) {printf("%s - ", $2); }  }' /tmp/ServerList-87d5b6ff65696ea676626c33201bd48d)
	        echo $LIST
	        CHOSEN_OVPN=$(whiptail --title "Menu example" --menu "Choose an option" 25 78 16 $LIST  3>&2 2>&1 1>&3)
	else
	        echo "things"
	fi
fi



echo "Chosen server: $CHOSEN_OVPN"

	# If there are less than 100 matches ask user to select from list, or refine search
	# If there are more than 100, ask user to refine search

# Ask user if they would like to ping server
	# Display results of ping, and ask user if they would like to continue 


