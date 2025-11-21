# Bersihkan konfigurasi lama
# jangan lupa sudo su dulu yaaa

ip addr flush dev eth0 || true
ip addr flush dev ens3 || true
ip route flush all

# Deteksi interface otomatis
INTERFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | head -n 1)

# Pasang IP dan Gateway
ip addr add 10.20.30.10/24 dev $INTERFACE
ip link set dev $INTERFACE up
ip route add default via 10.20.30.1
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# --- Tambahan untuk Web Server ---
apt update
apt install -y apache2
echo "<h1>Selamat Datang di Server RISET & IOT</h1>" > /var/www/html/index.html
service apache2 restart

# Test Ping ke Gateway
ping -c 2 10.20.30.1

