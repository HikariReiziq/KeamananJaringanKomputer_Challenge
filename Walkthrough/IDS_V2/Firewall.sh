#!/bin/bash
# Script Firewall (Referensi Teman - FINAL)

# 1. Reset
iptables -F
iptables -t nat -F
ip route flush all

# 2. IP Setup
ip addr flush dev eth0; ip addr add 192.168.1.2/24 dev eth0; ip link set eth0 up
ip addr flush dev eth1; ip addr add 10.20.0.1/24 dev eth1; ip link set eth1 up

# 3. Routing
ip route add default via 192.168.1.1
ip route add 10.20.0.0/16 via 10.20.0.2
# PENTING: Rute balik agar IDS (192.168.99.x) bisa internetan
ip route add 192.168.99.0/30 via 10.20.0.2

# 4. Forwarding & NAT
sysctl -w net.ipv4.ip_forward=1
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
# Allow All Forwarding (Biar gak pusing kena blok di firewall)
iptables -P FORWARD ACCEPT
iptables -P INPUT ACCEPT

echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "✅ Firewall Siap."