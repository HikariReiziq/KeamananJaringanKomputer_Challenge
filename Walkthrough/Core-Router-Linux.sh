#!/bin/bash
# Script Konfigurasi Core-Router-Linux (ALL IN ONE)

echo "[*] Mengkonfigurasi IP Address..."
# 1. Bersihkan Konfigurasi Lama
ip addr flush dev eth0
ip addr flush dev eth1
ip addr flush dev eth2
ip addr flush dev eth3
ip addr flush dev eth4
ip addr flush dev eth5
ip route flush all
iptables -F
iptables -X

# 2. Setup IP Address Interface
# Uplink ke Firewall (eth0)
ip addr add 10.20.0.2/24 dev eth0
ip link set dev eth0 up
ip route add default via 10.20.0.1

# Gateway Subnet
ip addr add 10.20.20.1/24 dev eth1; ip link set dev eth1 up # Akademik
ip addr add 10.20.30.1/24 dev eth2; ip link set dev eth2 up # Riset
ip addr add 10.20.10.1/24 dev eth3; ip link set dev eth3 up # Mahasiswa
ip addr add 10.20.40.1/24 dev eth4; ip link set dev eth4 up # Admin
ip addr add 10.20.50.1/24 dev eth5; ip link set dev eth5 up # Guest

# 3. Aktifkan Forwarding
sysctl -w net.ipv4.ip_forward=1
echo "nameserver 8.8.8.8" > /etc/resolv.conf

echo "[*] Menerapkan Kebijakan ACL (Access Control List)..."
# 4. Kebijakan Dasar: DENY ALL
iptables -P FORWARD DROP
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT

# 5. Whitelist Rules (Izin Akses)
# [A] Established Connection
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# [B] Admin (Super User)
iptables -A FORWARD -s 10.20.40.0/24 -j ACCEPT

# [C] Firewall Management
iptables -A FORWARD -s 10.20.0.1 -j ACCEPT

# [D] Mahasiswa (Akses Terbatas: Web Akademik Only)
iptables -A FORWARD -s 10.20.10.0/24 -d 10.20.20.0/24 -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -s 10.20.10.0/24 -d 10.20.20.0/24 -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -s 10.20.10.0/24 -d 10.20.20.0/24 -p icmp -j ACCEPT

# [E] Akademik (Akses SSH ke Riset)
iptables -A FORWARD -s 10.20.20.0/24 -d 10.20.30.0/24 -p tcp --dport 22 -j ACCEPT

# [F] Riset -> Akademik (Web Access/Data Exchange)
iptables -A FORWARD -s 10.20.30.0/24 -d 10.20.20.0/24 -p tcp --dport 80 -j ACCEPT

# [G] Internet Access (Semua Subnet)
iptables -A FORWARD -o eth0 -j ACCEPT

# 6. Logging
iptables -A FORWARD -m limit --limit 5/min -j LOG --log-prefix "CORE-BLOCK: "

echo "✅ Core Router Siap! (IP + ACL Loaded)"