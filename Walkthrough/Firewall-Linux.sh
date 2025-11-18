# 1. Hapus konfigurasi lama
ip addr flush dev eth0
ip addr flush dev eth1
ip route flush all

# 2. Interface ke Luar (Arah Edge)
ip addr add 192.168.1.2/24 dev eth0
ip link set dev eth0 up

# 3. Default Gateway (Arah ke Edge supaya bisa internetan)
ip route add default via 192.168.1.1

# 4. Interface ke Dalam (Arah Core)
ip addr add 10.20.0.1/24 dev eth1
ip link set dev eth1 up

# 5. Routing Balik (Supaya tahu jalan ke subnet Mahasiswa, Admin, dll)
# Kita arahkan seluruh blok 10.20.x.x ke Core Router
ip route add 10.20.0.0/16 via 10.20.0.2

# 6. Aktifkan Forwarding
sysctl -w net.ipv4.ip_forward=1