# TAHAP 1: Setting Awal IP Statis
# Konfigurasi Attacker (Mahasiswa)
hostnamectl set-hostname Attacker-Mahasiswa
ip addr flush dev eth0 || true
ip addr flush dev ens3 || true
ip route flush all

# Deteksi Interface Otomatis
INTERFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | head -n 1)

# Pasang IP Mahasiswa: 10.20.10.10
ip addr add 10.20.10.10/24 dev $INTERFACE
ip link set dev $INTERFACE up
ip route add default via 10.20.10.1
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# Test Ping ke Gateway
ping -c 2 10.20.10.1

# TAHAP 2: Beralih ke DHCP Client
# 1. Pasang IP Statis Sementara (Pancingan agar bisa internetan)
echo "[*] Mengaktifkan Koneksi Darurat..."
ip addr add 10.20.10.10/24 dev eth0
ip link set dev eth0 up
ip route add default via 10.20.10.1
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# 2. Install DHCP Client
echo "[*] Mengunduh DHCP Client..."
apt update
apt install -y isc-dhcp-client

# 3. Switch ke DHCP (Hapus IP Statis, Minta IP Dinamis)
echo "[*] Beralih ke Mode DHCP..."
ip addr flush dev eth0
ip route flush all
dhclient -v eth0

# 4. Validasi IP Baru
ip a | grep inet