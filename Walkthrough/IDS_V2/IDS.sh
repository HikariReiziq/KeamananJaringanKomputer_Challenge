#!/bin/bash
# Script Konfigurasi IDS Server (FINAL - LOG FORMATTED)

echo "[*] --- SETUP NETWORK IDS ---"

# 1. IP Setup (Static IP)
ip addr flush dev eth0
ip addr add 192.168.99.2/30 dev eth0
ip link set dev eth0 up
ip route add default via 192.168.99.1
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# 2. Cek Koneksi
echo "[*] Menunggu koneksi internet..."
for i in {1..10}; do
    if ping -c 1 8.8.8.8 &> /dev/null; then
        echo "✅ Internet Terhubung!"
        break
    else
        echo "⏳ Menunggu internet... (Coba ke-$i)"
        sleep 2
    fi
done

# 3. Repo & Install
echo "[*] Setup Repo & Install..."
cat > /etc/apt/sources.list <<REPO
deb http://deb.debian.org/debian/ bookworm main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
deb http://deb.debian.org/debian/ bookworm-updates main contrib non-free non-free-firmware
REPO

apt update
DEBIAN_FRONTEND=noninteractive apt install -y suricata ethtool

# 4. Config Rules Mata Elang (FORMAT INFORMATIF)
echo "[*] Membuat Rules Informatif..."
mkdir -p /etc/suricata/rules
cat > /etc/suricata/rules/mata_elang.rules <<RULES
# --- RULES DETEKSI OPERASI MATA ELANG ---

# 1. Scanning (Deteksi sapu jagat SYN Packet)
# Label: [BAHAYA]
alert tcp any any -> \$HOME_NET [22,80,443] (msg:"[BAHAYA] Port Scanning Terdeteksi (SYN Scan)"; flags:S; threshold: type both, track by_src, count 20, seconds 10; sid:1001; rev:1; classtype:attempted-recon;)

# 2. Brute Force SSH (Deteksi Login Gagal Berulang)
# Label: [KRITIS] - Karena menyangkut akses server
alert tcp any any -> \$HOME_NET 22 (msg:"[KRITIS] Percobaan Brute Force SSH (Multiple Login)"; flow:to_server,established; content:"SSH-"; nocase; threshold: type both, track by_src, count 3, seconds 30; sid:1002; rev:1; classtype:attempted-admin;)

# 3. Data Exfiltration (Deteksi File Download Berhasil)
# Label: [ALERT] - Indikasi Kebocoran Data
alert tcp \$HOME_NET 80 -> \$EXTERNAL_NET any (msg:"[ALERT] Indikasi Pencurian Data via HTTP (Exfiltration)"; flow:from_server,established; content:"HTTP/1."; content:"200 OK"; distance:0; sid:1003; rev:1; classtype:policy-violation;)

# 4. Ping Monitoring (Opsional - Agar layar tidak sepi)
# Label: [INFO]
alert icmp any any -> any any (msg:"[INFO] Paket ICMP Ping Terdeteksi (Log Dibatasi)"; itype:8; threshold: type limit, track by_src, count 1, seconds 60; sid:1004; rev:1; classtype:misc-activity;)
RULES

# 5. Config YAML
echo "[*] Update Config..."
cp /etc/suricata/suricata.yaml /etc/suricata/suricata.yaml.bak
sed -i 's/HOME_NET: "\[192.168.0.0\/16,10.0.0.0\/8,172.16.0.0\/12\]"/HOME_NET: "\[10.20.20.0\/24,10.20.30.0\/24\]"/' /etc/suricata/suricata.yaml
sed -i 's/EXTERNAL_NET: "any"/EXTERNAL_NET: "\[10.20.10.0\/24,10.20.50.0\/24\]"/' /etc/suricata/suricata.yaml
sed -i 's|default-rule-path: /var/lib/suricata/rules|default-rule-path: /etc/suricata/rules|' /etc/suricata/suricata.yaml
sed -i '/rule-files:/q' /etc/suricata/suricata.yaml
echo "  - mata_elang.rules" >> /etc/suricata/suricata.yaml

# 6. Matikan Offloading
ethtool -K eth0 rx off tx off sg off gso off gro off

echo "✅ IDS SIAP (Rules Optimized)! Restarting Service..."
# Paksa Restart Service agar config baru dimuat
killall suricata 2>/dev/null
rm -f /var/run/suricata.pid
suricata -D -c /etc/suricata/suricata.yaml -i eth0

echo "🚀 Monitoring Dimulai..."