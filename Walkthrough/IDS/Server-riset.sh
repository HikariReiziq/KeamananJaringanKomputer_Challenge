#!/bin/bash
# FIX JAM & INTERFACE
date -s "2025-12-08 12:00:00"
INT=\$(ip -o link show | awk -F': ' '{print \$2}' | grep -v lo | head -n 1)

ip addr flush dev \$INT
ip addr add 10.20.30.10/24 dev \$INT
ip link set dev \$INT up
ip route add default via 10.20.30.1
echo "nameserver 8.8.8.8" > /etc/resolv.conf

echo "[*] Repo Indo..."
cat > /etc/apt/sources.list <<REPO
deb http://kartolo.sby.datautama.net.id/debian/ stable main contrib non-free
deb http://kartolo.sby.datautama.net.id/debian-security/ stable-security main contrib non-free
REPO

echo "[*] Install Apache..."
apt -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false update
apt install -y apache2
# Set MTU agar paket besar tidak macet di GNS3
ip link set dev \$INT mtu 1400

echo "<h1>DATA RAHASIA RISET</h1>" > /var/www/html/rahasia.txt
service apache2 restart

echo "✅ Server Riset Siap!"