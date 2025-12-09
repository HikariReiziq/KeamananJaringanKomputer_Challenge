#!/bin/bash
# Reset
iptables -F
iptables -t nat -F
ip route flush all

# IP Setup
ip addr flush dev eth0; ip addr add 192.168.1.2/24 dev eth0; ip link set eth0 up
ip addr flush dev eth1; ip addr add 10.20.0.1/24 dev eth1; ip link set eth1 up

# Routing
ip route add default via 192.168.1.1
ip route add 10.20.0.0/16 via 10.20.0.2
# PENTING: Rute balik agar IDS (192.168.99.x) bisa internetan
ip route add 192.168.99.0/30 via 10.20.0.2

# Forwarding
sysctl -w net.ipv4.ip_forward=1
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT
iptables -A FORWARD -s 10.20.0.1 -j ACCEPT

echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "✅ Firewall Siap."