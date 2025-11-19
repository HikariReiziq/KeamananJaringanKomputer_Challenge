#!/bin/bash
# Script Konfigurasi Firewall-Linux (FINAL FIXED)

# 1. Reset
ip addr flush dev eth0
ip addr flush dev eth1
ip route flush all
iptables -F
iptables -t nat -F
iptables -X

# 2. Interface
ip addr add 192.168.1.2/24 dev eth0
ip link set dev eth0 up
ip route add default via 192.168.1.1

ip addr add 10.20.0.1/24 dev eth1
ip link set dev eth1 up
ip route add 10.20.0.0/16 via 10.20.0.2

# 3. Forwarding
sysctl -w net.ipv4.ip_forward=1

# 4. Kebijakan Dasar (DROP)
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# 5. Rules
# Allow Local & ICMP (Ping)
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p icmp -j ACCEPT
iptables -A FORWARD -p icmp -j ACCEPT

# Allow SSH dari Admin
iptables -A INPUT -s 10.20.40.0/24 -p tcp --dport 22 -j ACCEPT

# NAT Masquerade
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Allow Established Connections (PENTING!)
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow Internal -> Internet
iptables -A FORWARD -s 10.20.0.0/16 -i eth1 -o eth0 -j ACCEPT

# Allow Firewall Management (Firewall ke Bawah)
iptables -A FORWARD -s 10.20.0.1 -d 10.20.0.0/16 -j ACCEPT

# Logging
iptables -A FORWARD -m limit --limit 5/min -j LOG --log-prefix "FW-DROP: "

echo "✅ Firewall-Linux Updated!"

iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

echo "nameserver 8.8.8.8" > /etc/resolv.conf

ping -c 2 google.com