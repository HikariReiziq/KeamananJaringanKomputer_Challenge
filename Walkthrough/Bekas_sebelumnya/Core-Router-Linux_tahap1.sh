# 1. Bersihkan IP lama (PENTING: agar tidak bentrok)
ip addr flush dev eth0
ip addr flush dev eth1
ip addr flush dev eth2
ip addr flush dev eth3
ip addr flush dev eth4
ip addr flush dev eth5
ip route flush all

# 2. Uplink ke Firewall (eth0)
ip addr add 10.20.0.2/24 dev eth0
ip link set dev eth0 up
ip route add default via 10.20.0.1

# 3. Gateway Akademik (eth1) - [FIXED]
ip addr add 10.20.20.1/24 dev eth1
ip link set dev eth1 up

# 4. Gateway Riset (eth2) - [FIXED]
ip addr add 10.20.30.1/24 dev eth2
ip link set dev eth2 up

# 5. Gateway Mahasiswa (eth3) - [FIXED]
ip addr add 10.20.10.1/24 dev eth3
ip link set dev eth3 up

# 6. Gateway Admin (eth4) - [FIXED]
ip addr add 10.20.40.1/24 dev eth4
ip link set dev eth4 up

# 7. Gateway Guest (eth5) - [FIXED]
ip addr add 10.20.50.1/24 dev eth5
ip link set dev eth5 up

# 8. Aktifkan Forwarding & DNS
sysctl -w net.ipv4.ip_forward=1
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# 9. Test Ping (Momen Kebenaran)
ping -c 2 8.8.8.8