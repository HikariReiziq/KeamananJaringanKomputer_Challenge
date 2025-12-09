#!/bin/bash
# FIX JAM & MANUAL IP
date -s "2025-12-08 12:00:00"
INT=\$(ip -o link show | awk -F': ' '{print \$2}' | grep -v lo | head -n 1)

ip addr flush dev \$INT
ip addr add 10.20.10.99/24 dev \$INT
ip link set dev \$INT up
ip route add default via 10.20.10.1
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# Set MTU agar wget tidak macet
ip link set dev \$INT mtu 1400

echo "[*] Repo Indo..."
cat > /etc/apt/sources.list <<REPO
deb http://kartolo.sby.datautama.net.id/debian/ stable main contrib non-free
deb http://kartolo.sby.datautama.net.id/debian-security/ stable-security main contrib non-free
REPO

echo "[*] Install Nmap..."
apt -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false update
apt install -y nmap

echo "✅ Mahasiswa Siap (IP: 10.20.10.99)"