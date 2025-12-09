#!/bin/bash
# Config Internet
ip addr flush dev eth0
# Ganti IP ini jika NAT GNS3 kamu beda subnet
ip addr add 192.168.122.50/24 dev eth0
ip link set eth0 up
ip route add default via 192.168.122.1
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# Config LAN
ip addr flush dev eth1
ip addr add 192.168.1.1/24 dev eth1
ip link set eth1 up

# NAT
sysctl -w net.ipv4.ip_forward=1
iptables -t nat -F
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
ip route add 10.20.0.0/16 via 192.168.1.2

echo "✅ Edge Router Siap. Test Ping..."
ping -c 2 8.8.8.8