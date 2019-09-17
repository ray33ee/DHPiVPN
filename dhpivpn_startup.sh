
mount -t ext3 /dev/sda1 /mnt/hdd

iptables -t nat -A POSTROUTING -o tun-outgoing -j MASQUERADE
iptables -A FORWARD -i tun-incoming -o tun-outgoing -j ACCEPT
iptables -A FORWARD -i tun-outgoing -o tun-incoming -m state --state RELATED,ESTABLISHED -j ACCEPT
