# 1. Hapus konfigurasi lama (jika ada)
ip addr flush dev eth0
ip addr flush dev eth1
ip route flush all

# 2. Konfigurasi WAN (Internet) - Manual Static
# Kita pakai IP 192.168.122.50 (Aman untuk NAT GNS3)
ip addr add 192.168.122.50/24 dev eth0
ip link set dev eth0 up
ip route add default via 192.168.122.1

# 3. Konfigurasi DNS (Supaya bisa ping google.com)
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# 4. Konfigurasi LAN (Arah ke Firewall)
ip addr add 192.168.1.1/24 dev eth1
ip link set dev eth1 up

# 5. Aktifkan NAT & Forwarding
sysctl -w net.ipv4.ip_forward=1
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Tambahkan rute statis ke jaringan internal via Firewall
ip route add 10.20.0.0/16 via 192.168.1.2

# Cek tabel routing (Pastikan baris di atas muncul)
ip route

# 6. Validasi Cepat
ping -c 2 8.8.8.8