#!/bin/bash

set -e

echo "[*] Flush IPs"
ip addr flush dev eth0 || true
ip addr flush dev eth1 || true
ip route flush all

########################################
#  IP ADDRESS / INTERFACE CONFIG
########################################

echo "[*] Assign Interfaces"
# eth0 -> Edge Router
ip addr add 192.168.1.2/24 dev eth0
ip link set dev eth0 up

# eth1 -> Core Router
ip addr add 10.20.0.1/24 dev eth1
ip link set dev eth1 up

# Default route ke Edge Router
ip route add default via 192.168.1.1

########################################
#  IP FORWARDING
########################################

echo "[*] Enable forwarding"
sysctl -w net.ipv4.ip_forward=1

########################################
#  FIREWALL (iptables)
########################################

echo "[*] Flush iptables"
iptables -F
iptables -t nat -F
iptables -t mangle -F
iptables -X

# Default policies
iptables -P INPUT DROP          # aman
iptables -P FORWARD DROP        # aman, controlled
iptables -P OUTPUT ACCEPT       # bebas keluar

########################################
#  NAT (INTERNET)
########################################
echo "[*] Enable NAT MASQUERADE"
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

########################################
#  ALLOW INTERNAL LAN → INTERNET
########################################
echo "[*] Allow internal networks to go out"

# Allow established
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow all LAN (10.20.0.0/16) to go out via eth0 (internet)
iptables -A FORWARD -s 10.20.0.0/16 -o eth0 -j ACCEPT

########################################
#  BLOCK INTERNET → LAN (default DROP)
########################################

# allow ping dari Edge ke Firewall (opsional)
iptables -A INPUT -p icmp -j ACCEPT

# allow SSH from Core Router to firewall (opsional)
iptables -A INPUT -s 10.20.0.0/16 -p tcp --dport 22 -j ACCEPT

# block semua inbound baru dari internet (default drop)
iptables -A FORWARD -i eth0 -m conntrack --ctstate NEW -j DROP

########################################
#  LOGGING
########################################

iptables -A INPUT -m limit --limit 5/min -j LOG --log-prefix "FW_INPUT_DROP: "
iptables -A FORWARD -m limit --limit 5/min -j LOG --log-prefix "FW_FWD_DROP: "

########################################
#  SAVE RULES
########################################

echo "[*] Save iptables rules"
iptables-save > /etc/iptables.rules

echo "[*] Firewall Configuration DONE"
iptables -L -n --line-numbers