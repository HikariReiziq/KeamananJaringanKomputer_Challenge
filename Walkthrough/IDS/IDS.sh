#!/bin/bash
# FIX JAM (WAJIB UTK LOG)
date -s "2025-12-08 12:00:00"
INT=\$(ip -o link show | awk -F': ' '{print \$2}' | grep -v lo | head -n 1)

# IP Setup
ip addr flush dev \$INT
ip addr add 192.168.99.2/30 dev \$INT
ip link set dev \$INT up
ip route add default via 192.168.99.1
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# Repo Indo
cat > /etc/apt/sources.list <<REPO
deb http://kartolo.sby.datautama.net.id/debian/ stable main contrib non-free
deb http://kartolo.sby.datautama.net.id/debian-security/ stable-security main contrib non-free
REPO

# Install Suricata
apt -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false update
apt install -y suricata ethtool
service suricata stop
rm -f /var/run/suricata.pid

# CONFIG VALID (ANTI ERROR YAML)
echo "[*] Generating Clean Config..."
cat > /etc/suricata/suricata.yaml <<CONF
%YAML 1.1
---
default-rule-path: /etc/suricata/rules
vars:
  address-groups:
    HOME_NET: "[10.0.0.0/8, 192.168.0.0/16]"
    EXTERNAL_NET: "!\$HOME_NET"
    HTTP_SERVERS: "\$HOME_NET"
default-log-dir: /var/log/suricata/
outputs:
  - fast:
      enabled: yes
      filename: fast.log
      append: yes
  - eve-log:
      enabled: yes
      filetype: regular
      filename: eve.json
      types: [alert]
af-packet:
  - interface: \$INT
    cluster-id: 99
    cluster-type: cluster_flow
    defrag: yes
rule-files:
  - tugas.rules
CONF

# CUSTOM RULES (OPTIMIZED COMBINATION)
echo "[*] Writing Rules..."
mkdir -p /etc/suricata/rules
cat > /etc/suricata/rules/tugas.rules <<RULES
# 1. Port Scan (SENSITIF)
# Cukup 5 paket SYN dalam 10 detik langsung ALERT.
alert tcp 10.20.10.0/24 any -> 10.20.30.0/24 any (msg:"[BAHAYA] Port Scanning Terdeteksi (SYN Scan)"; flags:S; threshold: type both, track by_src, count 5, seconds 10; classtype:attempted-recon; sid:1001; rev:7;)

# 2. SSH Brute Force (SENSITIF)
# Cukup 3x percobaan dalam 30 detik langsung ALERT.
alert tcp any any -> 10.20.30.10 22 (msg:"[KRITIS] Percobaan Brute Force SSH (3x Percobaan)"; flags:S; threshold: type both, track by_src, count 3, seconds 30; classtype:attempted-admin; sid:1002; rev:7;)

# 3. Exfiltration Wget (ANTI-SPAM)
# Muncul cuma 1x per menit, biar log gak banjir.
alert ip 10.20.30.10 any -> 10.20.10.0/24 any (msg:"[ALERT] Indikasi Pencurian Data via HTTP (Exfiltration)"; content:"HTTP"; flow:from_server,established; threshold: type limit, track by_src, count 1, seconds 60; classtype:policy-violation; sid:1003; rev:7;)

# 4. Ping Test (ANTI-SPAM)
# Muncul cuma 1x per menit.
alert icmp any any -> any any (msg:"[INFO] Paket ICMP Ping Terdeteksi (Log Dibatasi)"; itype:8; threshold: type limit, track by_src, count 1, seconds 60; classtype:misc-activity; sid:1004; rev:7;)
RULES

ethtool -K \$INT rx off tx off sg off gso off gro off
echo "✅ IDS SIAP (Rules Optimized)!"
EOF

chmod +x IDS-Master-Setup.sh
./IDS-Master-Setup.sh