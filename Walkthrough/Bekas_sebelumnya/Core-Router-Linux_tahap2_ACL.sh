#!/bin/bash
# Script ACL Core Router (FINAL FIXED)

# 1. Reset
iptables -F
iptables -X

# 2. Policy: Blokir Semua
iptables -P FORWARD DROP
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT

# -----------------------------------
# WHITELIST (Siapa yang boleh lewat?)
# -----------------------------------

# [A] ESTABLISHED (Wajib)
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# [B] ADMIN (God Mode) - Boleh ke semua
iptables -A FORWARD -s 10.20.40.0/24 -j ACCEPT

# [C] FIREWALL (Management) - Boleh akses jaringan internal
# Agar firewall bisa ping server-server di bawah
iptables -A FORWARD -s 10.20.0.1 -j ACCEPT

# [D] MAHASISWA -> AKADEMIK (Layanan Kuliah)
iptables -A FORWARD -s 10.20.10.0/24 -d 10.20.20.0/24 -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -s 10.20.10.0/24 -d 10.20.20.0/24 -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -s 10.20.10.0/24 -d 10.20.20.0/24 -p icmp -j ACCEPT

# [E] AKADEMIK -> RISET (Kolaborasi SSH)
iptables -A FORWARD -s 10.20.20.0/24 -d 10.20.30.0/24 -p tcp --dport 22 -j ACCEPT

# [F] RISET -> AKADEMIK (Akses Web/Data - PERMINTAAN ANDA)
# Ini yang memperbaiki error "curl" tadi
iptables -A FORWARD -s 10.20.30.0/24 -d 10.20.20.0/24 -p tcp --dport 80 -j ACCEPT

# [G] INTERNET (Semua Boleh Keluar)
iptables -A FORWARD -o eth0 -j ACCEPT

# -----------------------------------
# LOGGING (Bukti Laporan)
# -----------------------------------
iptables -A FORWARD -m limit --limit 5/min -j LOG --log-prefix "CORE-BLOCK: "

echo "✅ Core Router ACL Updated!"