#!/bin/bash
# Script Instalasi Suricata di CORE ROUTER (Internal IDS)

echo "[*] --- FASE 4.4: INSTALASI IDS DI CORE ROUTER ---"

# 1. Cek Koneksi Internet (Wajib untuk install)
echo "[*] Cek koneksi internet..."
if ping -c 1 8.8.8.8 &> /dev/null; then
    echo "✅ Internet OK."
else
    echo "❌ Gagal koneksi internet! Cek Gateway/DNS Core Router."
    exit 1
fi

# 2. Install Suricata & Ethtool
echo "[*] Menginstall Suricata..."
apt update
DEBIAN_FRONTEND=noninteractive apt install -y suricata ethtool

# 3. Stop service dulu
if [ -f /etc/init.d/suricata ]; then
    service suricata stop
fi

# 4. Konfigurasi Rules (Sama seperti Firewall, tapi kita pasang di Core)
echo "[*] Membuat Rules Deteksi..."
mkdir -p /etc/suricata/rules
cat > /etc/suricata/rules/local.rules <<EOF
# --- RULES DETEKSI INTERNAL ---
# 1. Deteksi Ping Antar Host
alert icmp any any -> any any (msg:"CORE IDS: Ada Ping Terdeteksi!"; sid:1000001; rev:1; classtype:icmp-event;)

# 2. Deteksi Percobaan SSH (Port 22)
alert tcp any any -> any 22 (msg:"CORE IDS: Percobaan Koneksi SSH!"; sid:1000002; rev:1; classtype:attempted-admin;)

# 3. Deteksi Akses Web (Port 80)
alert tcp any any -> any 80 (msg:"CORE IDS: Akses Web Server Detected"; sid:1000003; rev:1; classtype:web-application-activity;)

# 4. Deteksi DDoS (SYN Flood)
alert tcp any any -> any 80 (msg:"CORE IDS: Potensi SYN Flood Attack"; flags:S; threshold: type both, track by_src, count 20, seconds 10; sid:1000004; rev:1;)
EOF

# 5. Update Konfigurasi YAML
echo "[*] Mengupdate config suricata.yaml..."
cp /etc/suricata/suricata.yaml /etc/suricata/suricata.yaml.bak

# Pointing rule path
sed -i 's|default-rule-path: /var/lib/suricata/rules|default-rule-path: /etc/suricata/rules|' /etc/suricata/suricata.yaml
sed -i 's|default-rule-path: /usr/share/suricata/rules|default-rule-path: /etc/suricata/rules|' /etc/suricata/suricata.yaml

# Tambahkan local.rules
sed -i '/rule-files:/q' /etc/suricata/suricata.yaml
echo "  - local.rules" >> /etc/suricata/suricata.yaml

# 6. Matikan Offloading di SEMUA Interface Core (Penting!)
echo "[*] Optimasi Interface..."
for i in eth0 eth1 eth2 eth3 eth4 eth5; do
    ethtool -K $i rx off tx off sg off gso off gro off 2>/dev/null || true
done

echo "✅ CORE IDS SIAP! Silakan jalankan validasi."