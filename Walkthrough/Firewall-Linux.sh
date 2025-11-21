#!/bin/bash
# Script Konfigurasi Firewall-Linux (FINAL - SECURITY HARDENED)

echo "[*] Resetting Firewall..."
# 1. Reset Konfigurasi
ip addr flush dev eth0
ip addr flush dev eth1
ip route flush all
iptables -F
iptables -t nat -F
iptables -X

echo "[*] Configuring Interfaces..."
# 2. Konfigurasi Interface
# eth0 -> Internet (Arah Edge)
ip addr add 192.168.1.2/24 dev eth0
ip link set dev eth0 up
# Gateway ke Internet (Edge Router)
ip route add default via 192.168.1.1

# eth1 -> LAN Transit (Arah Core)
ip addr add 10.20.0.1/24 dev eth1
ip link set dev eth1 up
# Rute ke seluruh subnet kampus via Core Router
ip route add 10.20.0.0/16 via 10.20.0.2

# 3. Aktifkan IP Forwarding
sysctl -w net.ipv4.ip_forward=1

echo "[*] Applying Security Rules..."
# 4. Kebijakan Dasar Firewall (Security Policy)
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# ==========================================
# RULES: INPUT CHAIN (Traffic ke Firewall)
# ==========================================
# Allow Loopback
iptables -A INPUT -i lo -j ACCEPT
# Allow Ping (ICMP) untuk troubleshooting
iptables -A INPUT -p icmp -j ACCEPT
# Allow SSH dari Admin
iptables -A INPUT -s 10.20.40.0/24 -p tcp --dport 22 -j ACCEPT
# [FIX DNS] Allow Reply Packet (Agar Firewall bisa DNS/Update)
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# ==========================================
# RULES: FORWARD CHAIN (Traffic User)
# ==========================================

# [HARDENING] Blokir Paket Baru dari Luar yg mencoba masuk ke Dalam
# Aturan ini ditaruh paling atas (-I) untuk memastikan keamanan mutlak
iptables -I FORWARD 1 -i eth0 -o eth1 -m conntrack --ctstate NEW -j LOG --log-prefix "FW-BLOCK-EXT: "
iptables -I FORWARD 2 -i eth0 -o eth1 -m conntrack --ctstate NEW -j DROP

# Allow Established Connections (Wajib agar koneksi tidak putus)
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow Internal LAN -> Internet (Hanya boleh keluar, tidak boleh masuk sembarangan)
iptables -A FORWARD -s 10.20.0.0/16 -i eth1 -o eth0 -j ACCEPT

# Allow Firewall Management (Firewall ke Subnet Bawah)
iptables -A FORWARD -s 10.20.0.1 -d 10.20.0.0/16 -j ACCEPT

# 5. NAT Masquerade
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

echo "✅ Firewall-Linux SIAP! (Hardened & Leak-Proof)"