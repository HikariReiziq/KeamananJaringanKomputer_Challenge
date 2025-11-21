#!/bin/bash
# Script Konfigurasi Nginx Load Balancer

# 1. Network Config
ip addr flush dev eth0 || true
ip addr flush dev ens3 || true
ip route flush all

# Deteksi Interface
INTERFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | head -n 1)

# IP Load Balancer: .5
ip addr add 10.20.30.5/24 dev $INTERFACE
ip link set dev $INTERFACE up
ip route add default via 10.20.30.1
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# 2. Install Nginx
apt update
apt install -y nginx

# 3. Konfigurasi Load Balancing (Round Robin)
# Kita menimpa config default nginx
cat > /etc/nginx/sites-available/default <<EOF
upstream backend_servers {
    server 10.20.30.10; # Server Riset
    server 10.20.30.20; # Server Smart City
}

server {
    listen 80;
    
    location / {
        proxy_pass http://backend_servers;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

# 4. Restart Nginx
service nginx restart

echo "✅ Load Balancer Siap di 10.20.30.5"