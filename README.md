# Laporan Tugas Akhir - ITS Secure Network Challenge

**Mata Kuliah:** Keamanan Jaringan Komputer  
**Departemen:** Teknologi Informasi - ITS  
**Kelas:** C - Kelompok 1 <br>
**Judul:** Deteksi Serangan Menggunakan IDS Suricata/Snort

## Anggota Kelompok

| Nama | NRP |
| :--- | :--- |
| Syela Zeruya Tandi Lalong | 5027231076 |
| Tasya Aulia Darmawan | 5027241009 |
| Azaria Raissa Maulidinnisa | 5027241043 |
| M. Hikari Reiziq Rakhmadinta | 5027241079 |
| Ni'mah Fauziyyah Atok | 5027241103 |

---
## Latar Belakang

Departemen Teknologi Informasi ITS melaporkan adanya indikasi kebocoran data berskala kecil pada subnet Riset & IoT (10.20.30.0/24). Berdasarkan log firewall, terdeteksi adanya lonjakan lalu lintas mencurigakan yang berasal dari subnet Mahasiswa (10.20.10.0/24). Untuk itu, tim ditugaskan melakukan pemasangan IDS (Suricata/Snort dalam mode monitoring) guna mendeteksi pola serangan yang tidak dapat dideteksi oleh firewall. Berikut adalah beberapa kejanggalan yang ditemukan:

1.  **Scanning:** Pencarian port terbuka.
2.  **Brute Force:** Upaya paksa masuk ke server.
3.  **Exfiltration:** Pengambilan data rahasia.
   
## Desain Topologi Jaringan

Berikut adalah desain akhir infrastruktur jaringan yang telah kami implementasikan. Topologi ini dirancang menggunakan prinsip **Defense in Depth** (Pertahanan Berlapis) dan **Modularitas** untuk menjamin keamanan, ketersediaan, dan kemudahan pengembangan.

![Topologi Jaringan](/Assets/topologi.png)
**Lokasi IDS:** Node Terpisah (Out-of-Band) yang terhubung ke interface `eth6` pada **Core Router**.
**Alasan Pemilihan (Traffic Mirroring):**
* **Visibilitas Sentral:** Core Router adalah titik temu antar-subnet (Mahasiswa XXX Riset).
* **Kinerja:** Memisahkan IDS dari jalur utama (bukan inline) menjaga throughput jaringan tetap stabil.

### Komponen Utama Topologi:
1.  **Perimeter Security (Edge & Firewall):** Melindungi jaringan kampus dari ancaman eksternal dan menangani lalu lintas keluar-masuk internet (NAT).
2.  **Internal Security (Core Router ACL):** Menerapkan segmentasi jaringan yang ketat antar departemen (Mahasiswa, Admin, Riset, Guest) untuk mencegah pergerakan lateral serangan.
3.  **High Availability (Load Balancer):** Menggunakan Nginx Load Balancer pada subnet Riset untuk mendistribusikan beban lalu lintas ke Server Riset dan Server Smart City.
4.  **Dynamic Addressing:** Implementasi DHCP Server pada Core Router untuk manajemen IP otomatis pada subnet publik (Mahasiswa & Guest).

---

## Konfigurasi IDS

**1. Arsitektur Operasi & Interface**

| Parameter | Detail | Keterangan |
| :--- | :--- | :--- |
| Node Suricata | Node Terpisah (Out-of-Band) | Tidak menghalangi traffic utama |
| Interface Monitor | eth0 | Menerima mirroring paket dari Core Router |
| Operation Mode | Passive/Monitor Mode | Dijalankan dengan ```-i $INT``` |
| Optimasi Kinerja | ```ethtool -K \$INT rx off ...``` | Optimasi kernel pada NIC untuk mengurangi beban CPU (offloading checksums, dll.) |

**2. Variabel Jaringan Utama**

| Variabel Jaringan | Value | Keterangan |
| :--- | :--- | :--- |
| HOME_NET | [10.0.0.0/8, 192.168.0.0/16] | Mencakup seluruh jaringan internal ITS (termasuk Riset 10.20.30.0/24 dan Akademik 10.20.20.0/24). |
| EXTERNAL_NET | !$HOME_NET | Semua, kecuali HOME_NET|
| Packet Acquisition | af-packet | Untuk efisiensi tinggi dalam membaca packet yang di mirror |

## Custom Rules
### Files: 
```tugas.rules```

1. Deteksi Port Scanning (SID: 1001) (Reconnaissance)

```
alert tcp 10.20.10.0/24 any -> 10.20.30.0/24 any (msg:"[BAHAYA] Port Scanning Terdeteksi (SYN Scan)"; flags:S; threshold: type both, track by_src, count 5, seconds 10; classtype:attempted-recon; sid:1001; rev:7;)
```
  
Rule ini mendeteksi jika IP dari subnet Mahasiswa (10.20.10.0/24) mengirimkan 5 paket SYN (inisiasi koneksi) dalam waktu 10 detik menuju subnet Riset, mengindikasikan upaya pemindaian cepat.
    
2. Deteksi Brute Force SSH (SID: 1002)
    
```
alert tcp any any -> 10.20.30.10 22 (msg:"[KRITIS] Percobaan Brute Force SSH (3x Percobaan)"; flags:S; threshold: type both, track by_src, count 3, seconds 30; classtype:attempted-admin; sid:1002; rev:7;)
```
    
Rule ini memicu peringatan jika terdeteksi lebih dari 3 percobaan koneksi SSH (melalui flag SYN) dari sumber manapun menuju IP Server Riset (10.20.30.10) dalam waktu 30 detik.
    
3. Deteksi Data Exfiltration (SID: 1003) (Pencurian Data)
    
```
alert ip 10.20.30.10 any -> 10.20.10.0/24 any (msg:"[ALERT] Indikasi Pencurian Data via HTTP (Exfiltration)"; content:"HTTP"; flow:from_server,established; threshold: type limit, track by_src, count 1, seconds 60; classtype:policy-violation; sid:1003; rev:7;)
```
    
Rule ini mendeteksi aktivitas transfer file yang keluar (flow:from_server,established) dari Server Riset (10.20.30.10) menuju Subnet Mahasiswa (10.20.10.0/24) yang menggunakan protokol HTTP. Log dibatasi (anti-spam) menjadi 1x per menit.

4. Deteksi Ping Test (SID: 1004)

```
alert icmp any any -> any any (msg:"[INFO] Paket ICMP Ping Terdeteksi (Log Dibatasi)"; itype:8; threshold: type limit, track by_src, count 1, seconds 60; classtype:misc-activity; sid:1004; rev:7;)
```

Rule ini mendeteksi paket ICMP Echo Request (itype:8) dan mencatatnya sebagai informasi. Log dibatasi (anti-spam) menjadi 1x per menit.

---
## Simulasi Serangan

1. Port Scanning (Nmap)

Command:

```
nmap -p 22,80,443 --open 10.20.30.10
```

Log Alert IDS:
[masukin docum nmap raissa]

2. SSH Brute Force

Command:

```
for i in {1..5}; do ssh -o ConnectTimeout=2 -o BatchMode=yes targetuser@10.20.30.10 "exit"; done
```
[masukin docum ssh brutfor raissa]

3. Data Exflitration (HTTP Wget)

Command: 

```
wget http://10.20.30.10/index.html
```
[masukin docum data exfiltration raissa]

Log Alert IDS:

[masukin docum data exfiltration_alert_ raissa]

---
## Hasil Analisis Singkat

   Serangan Port Scanning adalah yang paling mudah dan cepat memicu alert. Hal ini karena Nmap mengirimkan paket SYN dalam jumlah masif dalam waktu sangat singkat, sehingga langsung memicu ambang batas (threshold) pada rule IDS tanpa ambiguitas.
    
   Dalam simulasi ini, false positive ditekan seminimal mungkin dengan mendefinisikan $HOME_NET dan $EXTERNAL_NET secara spesifik. Namun, rule Data Exfiltration berpotensi menghasilkan false positive jika Mahasiswa memang diizinkan mengakses halaman web publik di server Riset, karena setiap respon "200 OK" akan dianggap sebagai pencurian data. Perlu penyesuaian rule content (misal: hanya mendeteksi file .conf atau .pdf rahasia).
    
   **Enkripsi:** Saat ini deteksi exfiltration hanya bekerja pada HTTP (Plaintext). Jika Server Riset menggunakan HTTPS (Port 443), IDS tidak akan bisa membaca konten "200 OK" atau nama file tanpa melakukan *SSL Termination/Inspection*.

   
   **IPS:** Mengubah mode dari IDS (Deteksi) menjadi IPS (Pencegahan) agar Core Router dapat memblokir IP penyerang secara otomatis setelah alert muncul.
an selanjutnya, sistem ini dapat ditingkatkan dengan mengintegrasikan Suricata dalam mode **IPS (Intrusion Prevention System)** agar dapat memblokir serangan DDoS secara otomatis tanpa intervensi manual, serta menggunakan **SIEM (Security Information and Event Management)** untuk sentralisasi log dari Firewall dan Core Router.
