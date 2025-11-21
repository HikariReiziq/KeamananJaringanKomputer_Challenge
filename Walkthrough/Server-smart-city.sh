#!/bin/bash
# Konfigurasi Server Smart City (Lab Baru)

# 1. Network Config
ip addr flush dev eth0 || true
ip addr flush dev ens3 || true
ip route flush all

# Deteksi Interface
INTERFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | head -n 1)

# IP: .20 (IP Baru dalam subnet Riset)
ip addr add 10.20.30.20/24 dev $INTERFACE
ip link set dev $INTERFACE up
ip route add default via 10.20.30.1
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# 2. Install & Config Apache
apt update
apt install -y apache2

# Buat halaman website identitas
echo "<h1>Ini adalah Dashboard SMART CITY - Monitoring Kota</h1>" > /var/www/html/index.html

# Restart service
service apache2 restart

echo "✅ Server Smart City Siap"