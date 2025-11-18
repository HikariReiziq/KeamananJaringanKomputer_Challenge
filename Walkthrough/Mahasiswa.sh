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