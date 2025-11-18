#!/bin/bash
# Script Konfigurasi Firewall-Linux (Fixed Version)

# 1. Bersihkan Konfigurasi Lama
ip addr flush dev eth0
ip addr flush dev eth1
ip route flush all
iptables -F
iptables -t nat -F

# 2. Konfigurasi Interface
# eth0 -> Internet (Arah Edge)
ip addr add 192.168.1.2/24 dev eth0
ip link set dev eth0 up
# Gateway ke Internet (via Edge Router)
ip route add default via 192.168.1.1

# eth1 -> LAN Transit (Arah Core)
ip addr add 10.20.0.1/24 dev eth1
ip link set dev eth1 up

# [PENTING] Rute ke seluruh subnet kampus via Core Router
ip route add 10.20.0.0/16 via 10.20.0.2

# 3. Aktifkan IP Forwarding
sysctl -w net.ipv4.ip_forward=1

# 4. Konfigurasi Firewall (IPTABLES)
# Kebijakan Dasar: Blokir semua forwarding kecuali diizinkan
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Izinkan akses Loopback & Ping (ICMP)
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p icmp -j ACCEPT
iptables -A FORWARD -p icmp -j ACCEPT

# Izinkan akses SSH ke Firewall ini dari Admin
iptables -A INPUT -s 10.20.40.0/24 -p tcp --dport 22 -j ACCEPT

# NAT Masquerade (Agar klien bisa internetan)
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# --- RULE TRAFIK ---
# 1. Izinkan koneksi yang sudah terjalin (ESTABLISHED)
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# 2. Izinkan LAN Internal akses ke Internet (Outbound)
iptables -A FORWARD -s 10.20.0.0/16 -i eth1 -o eth0 -j ACCEPT

# Logging paket yang diblokir
iptables -A FORWARD -m limit --limit 5/min -j LOG --log-prefix "FW-DROP: "

echo "Konfigurasi Firewall & Routing Selesai."