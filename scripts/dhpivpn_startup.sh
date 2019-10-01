
# Mount large volume for torrenting
mount -t ext3 /dev/sda1 /mnt/hdd

# Firewall rules fix incoming-outgoing issue
iptables -t nat -A POSTROUTING -o tun-outgoing -j MASQUERADE
iptables -A FORWARD -i tun-incoming -o tun-outgoing -j ACCEPT
iptables -A FORWARD -i tun-outgoing -o tun-incoming -m state --state RELATED,ESTABLISHED -j ACCEPT

#Accept incoming traffic on all interfaces, but limit eth0 to VPN only
sudo iptables -A INPUT -i eth0 -m state --state NEW -p PROTOCOL --dport PORT -j ACCEPT
sudo iptables -A INPUT -i tun-incoming -j ACCEPT
sudo iptables -A INPUT -i tun-outgoing -j ACCEPT
#Allow forwarding traffic between subnets
sudo iptables -A FORWARD -i tun-incoming -j ACCEPT
sudo iptables -A FORWARD -i tun-outgoing -j ACCEPT
#Forward traffic through eth0
sudo iptables -A FORWARD -i tun-incoming -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i tun-outgoing -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
#Forward traffic through tun-incoming
sudo iptables -A FORWARD -i eth0 -o tun-incoming -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i tun-outgoing -o tun-incoming -m state --state RELATED,ESTABLISHED -j ACCEPT
#Forward traffic through tun-outgoing
sudo iptables -A FORWARD -i eth0 -o tun-outgoing -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i eth0 -o tun-outgoing -m state --state RELATED,ESTABLISHED -j ACCEPT
#MASQ tun-incoming as eth0
sudo iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE