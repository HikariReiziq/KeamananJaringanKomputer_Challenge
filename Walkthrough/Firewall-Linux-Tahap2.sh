#!/bin/bash
# Script Perbaikan Instalasi Suricata (Fixed & Compatible)

echo "[*] --- FASE 4.1: PERBAIKAN KONEKSI & INSTALASI ---"

# 1. PERBAIKAN DNS (CRITICAL)
echo "[*] Memperbaiki konfigurasi DNS..."
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# 2. Update Repository
echo "[*] Update repository..."
apt update

# 3. Install Suricata & Ethtool
# Kita tambahkan 'ethtool' karena tadi error command not found
echo "[*] Menginstall Suricata dan Ethtool..."
DEBIAN_FRONTEND=noninteractive apt install -y suricata ethtool

# 4. Stop service (Gunakan 'service' pengganti 'systemctl')
if [ -f /etc/init.d/suricata ]; then
    service suricata stop
    echo "✅ Service Suricata dihentikan sementara."
else
    echo "⚠️ Warning: Service Suricata belum terinstall sempurna."
fi

echo "[*] --- FASE 4.2: KONFIGURASI RULES ---"

# 5. Cek apakah instalasi berhasil
if [ ! -d "/etc/suricata" ]; then
    echo "❌ ERROR FATAL: Instalasi Gagal. Cek koneksi internet Anda."
    exit 1
fi

# 6. Buat File Rules Lokal
echo "[*] Membuat rules deteksi..."
mkdir -p /etc/suricata/rules
cat > /etc/suricata/rules/local.rules <<EOF
# --- CUSTOM RULES KELOMPOK 1 ---
# 1. Deteksi Ping (ICMP)
alert icmp any any -> any any (msg:"IDS ALERT: Ada Ping Terdeteksi!"; sid:1000001; rev:1; classtype:icmp-event;)

# 2. Deteksi SSH (Port 22)
alert tcp any any -> any 22 (msg:"IDS ALERT: Percobaan Koneksi SSH!"; sid:1000002; rev:1; classtype:attempted-admin;)

# 3. Deteksi Web (Port 80)
alert tcp any any -> any 80 (msg:"IDS ALERT: Akses Web Server Detected"; sid:1000003; rev:1; classtype:web-application-activity;)

# 4. Deteksi DDoS (SYN Flood)
alert tcp any any -> any 80 (msg:"IDS ALERT: Potensi SYN Flood Attack"; flags:S; threshold: type both, track by_src, count 20, seconds 10; sid:1000004; rev:1;)
EOF

# 7. Update Konfigurasi YAML
echo "[*] Mengupdate suricata.yaml..."
cp /etc/suricata/suricata.yaml /etc/suricata/suricata.yaml.bak

# Pointing rule path ke /etc/suricata/rules
sed -i 's|default-rule-path: /var/lib/suricata/rules|default-rule-path: /etc/suricata/rules|' /etc/suricata/suricata.yaml
sed -i 's|default-rule-path: /usr/share/suricata/rules|default-rule-path: /etc/suricata/rules|' /etc/suricata/suricata.yaml

# Tambahkan local.rules
# Hapus baris rule-files lama dan ganti baru agar rapi
sed -i '/rule-files:/q' /etc/suricata/suricata.yaml
echo "  - local.rules" >> /etc/suricata/suricata.yaml

# 8. Matikan Offloading (Penting untuk IDS Virtual)
echo "[*] Mengatur interface card..."
ethtool -K eth0 rx off tx off sg off gso off gro off
ethtool -K eth1 rx off tx off sg off gso off gro off

echo "✅ FASE 4.1 & 4.2 SELESAI! Suricata siap dijalankan."