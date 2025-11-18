# Tahap 1

# Konfigurasi Server Akademik
hostnamectl set-hostname Server-Akademik
ip addr flush dev eth0 || true
ip addr flush dev ens3 || true
ip route flush all

# Sesuaikan 'ens3' di bawah jika interface Anda bernama lain (cek dengan 'ip a')
# Biasanya di GNS3 Debian appliance interfacenya bernama 'ens3' atau 'eth0'
INTERFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | head -n 1)

ip addr add 10.20.20.10/24 dev $INTERFACE
ip link set dev $INTERFACE up
ip route add default via 10.20.20.1
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# Test Koneksi ke Gateway (Core Router)
ping -c 2 10.20.20.1


# Tahap 2
# Update daftar paket
apt update

# Install Apache Web Server
apt install -y apache2

# Pastikan service jalan
service apache2 start

# Buat halaman web sederhana untuk tanda pengenal
echo "<h1>Ini Server Akademik - RAHASIA</h1>" > /var/www/html/index.html