# Konfigurasi Admin Workstation
ip addr flush dev eth0 || true
ip addr flush dev ens3 || true
ip route flush all

# Deteksi Interface
INTERFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | head -n 1)

# IP Admin: 10.20.40.10
ip addr add 10.20.40.10/24 dev $INTERFACE
ip link set dev $INTERFACE up
ip route add default via 10.20.40.1
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# Test Ping ke Gateway
ping -c 2 10.20.40.1