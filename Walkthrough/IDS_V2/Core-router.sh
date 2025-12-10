#!/bin/bash
# Script Core Router (Referensi Teman - FINAL)

# 1. Config Network & Reset
echo "[*] Reset Network..."
for i in {0..6}; do ip addr flush dev eth$i; done
ip route flush all
iptables -F
iptables -t mangle -F

echo "[*] Set IP Address..."
ip addr add 10.20.0.2/24 dev eth0; ip link set eth0 up
ip route add default via 10.20.0.1
ip addr add 10.20.20.1/24 dev eth1; ip link set eth1 up
ip addr add 10.20.30.1/24 dev eth2; ip link set eth2 up
ip addr add 10.20.10.1/24 dev eth3; ip link set eth3 up
ip addr add 10.20.40.1/24 dev eth4; ip link set eth4 up
ip addr add 10.20.50.1/24 dev eth5; ip link set eth5 up
# JALUR KHUSUS IDS (eth6)
ip addr add 192.168.99.1/30 dev eth6; ip link set eth6 up

sysctl -w net.ipv4.ip_forward=1
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# 2. MIRRORING TRAFFIC (PENTING)
IDS_IP="192.168.99.2"
# Mirror trafik MASUK dari Mahasiswa (Scanning/Brute Force)
iptables -t mangle -A PREROUTING -s 10.20.10.0/24 -j TEE --gateway $IDS_IP
# Mirror trafik KELUAR ke Mahasiswa (Exfiltration/Download)
iptables -t mangle -A POSTROUTING -d 10.20.10.0/24 -j TEE --gateway $IDS_IP
# Mirror trafik Riset (Agar respon server terlihat)
iptables -t mangle -A PREROUTING -s 10.20.30.0/24 -j TEE --gateway $IDS_IP

# 3. ACL (MODE JEBAKAN / PERMISSIVE)
# Kita izinkan serangan agar IDS bisa mendeteksi full flow
iptables -P FORWARD ACCEPT
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT

# 4. INSTALL DHCP (Jika belum)
if [ ! -f /etc/init.d/isc-dhcp-server ]; then
    echo "[*] Install DHCP..."
    apt update
    apt install -y isc-dhcp-server
fi

# Config DHCP
cat > /etc/dhcp/dhcpd.conf <<DHCP
default-lease-time 600;
max-lease-time 7200;
authoritative;
subnet 10.20.10.0 netmask 255.255.255.0 {
    range 10.20.10.100 10.20.10.200;
    option routers 10.20.10.1;
    option domain-name-servers 8.8.8.8;
}
subnet 10.20.50.0 netmask 255.255.255.0 {
    range 10.20.50.100 10.20.50.200;
    option routers 10.20.50.1;
    option domain-name-servers 8.8.8.8;
}
DHCP
sed -i 's/INTERFACESv4=""/INTERFACESv4="eth3 eth5"/' /etc/default/isc-dhcp-server
service isc-dhcp-server restart

echo "✅ Core Router Final Siap!"