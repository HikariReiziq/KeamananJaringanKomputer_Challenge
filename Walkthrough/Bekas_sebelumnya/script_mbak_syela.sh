#!/bin/bash

# 1. Bersihkan IP lama
ip addr flush dev eth0
ip addr flush dev eth1
ip addr flush dev eth2
ip addr flush dev eth3
ip addr flush dev eth4
ip addr flush dev eth5
ip route flush all

# 2. Uplink ke Firewall (eth0)
ip addr add 10.20.0.2/24 dev eth0
ip link set eth0 up
ip route add default via 10.20.0.1

# 3–7. Subnet Interfaces
ip addr add 10.20.20.1/24 dev eth1; ip link set eth1 up
ip addr add 10.20.30.1/24 dev eth2; ip link set eth2 up
ip addr add 10.20.10.1/24 dev eth3; ip link set eth3 up
ip addr add 10.20.40.1/24 dev eth4; ip link set eth4 up
ip addr add 10.20.50.1/24 dev eth5; ip link set eth5 up

# 8. Forwarding & DNS
sysctl -w net.ipv4.ip_forward=1
echo "nameserver 8.8.8.8" > /etc/resolv.conf

########################################
#  ACL RULES
########################################

iptables -F
iptables -X
iptables -P FORWARD DROP

# Allow established
iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

# Allow ALL subnets → Internet (via eth0)
iptables -A FORWARD -s 10.20.0.0/16 -o eth0 -j ACCEPT

############################
# ADMIN — full access
############################
iptables -A FORWARD -s 10.20.40.0/24 -j ACCEPT

############################
# AKADEMIK — boleh semua kecuali blok gambar
############################
iptables -A FORWARD -s 10.20.20.0/24 -d 10.20.30.0/24 -j ACCEPT
iptables -A FORWARD -s 10.20.30.0/24 -d 10.20.20.0/24 -j ACCEPT
iptables -A FORWARD -s 10.20.20.0/24 -j ACCEPT

############################
# RISET
############################
iptables -A FORWARD -s 10.20.30.0/24 -d 10.20.40.0/24 -j DROP
iptables -A FORWARD -s 10.20.30.0/24 -j ACCEPT

############################
# MAHASISWA
############################
iptables -A FORWARD -s 10.20.10.0/24 -d 10.20.40.0/24 -j DROP
iptables -A FORWARD -s 10.20.10.0/24 -d 10.20.30.0/24 -j DROP
iptables -A FORWARD -s 10.20.10.0/24 -d 10.20.20.0/24 -j ACCEPT
iptables -A FORWARD -s 10.20.10.0/24 -j ACCEPT

############################
# GUEST — internet only
############################
iptables -A FORWARD -s 10.20.50.0/24 -d 10.20.50.0/24 -j ACCEPT
iptables -A FORWARD -s 10.20.50.0/24 -d 10.20.0.0/16 -j DROP
iptables -A FORWARD -s 10.20.50.0/24 -j ACCEPT

# Logging
iptables -A FORWARD -m limit --limit 4/min -j LOG --log-prefix "CORE_DROP: "