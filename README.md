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

### Komponen Utama Topologi:
1.  **Perimeter Security (Edge & Firewall):** Melindungi jaringan kampus dari ancaman eksternal dan menangani lalu lintas keluar-masuk internet (NAT).
2.  **Internal Security (Core Router ACL):** Menerapkan segmentasi jaringan yang ketat antar departemen (Mahasiswa, Admin, Riset, Guest) untuk mencegah pergerakan lateral serangan.
3.  **High Availability (Load Balancer):** Menggunakan Nginx Load Balancer pada subnet Riset untuk mendistribusikan beban lalu lintas ke Server Riset dan Server Smart City.
4.  **Dynamic Addressing:** Implementasi DHCP Server pada Core Router untuk manajemen IP otomatis pada subnet publik (Mahasiswa & Guest).

---

## Custom Rules

1. Deteksi Port Scanning (Reconnaissance)

```
alert tcp any any -> $HOME_NET [22,80,443] (msg:"[BAHAYA] Port Scanning Terdeteksi (SYN Scan)"; flags:S; threshold: type both, track by_src, count 20, seconds 10; sid:1001; rev:1; classtype:attempted-recon;)
```
  
Rule ini mendeteksi jika ada satu IP asal yang mengirimkan lebih dari 20 paket `SYN` (inisiasi koneksi) dalam waktu 10 detik menuju port kritis (SSH, HTTP, HTTPS) di jaringan internal.
    
2. Deteksi Brute Force SSH
    
```
alert tcp any any -> $HOME_NET 22 (msg:"[KRITIS] Percobaan Brute Force SSH (3x Percobaan)"; flow:to_server,established; content:"SSH-"; nocase; threshold: type both, track by_src, count 3, seconds 30; sid:1002; rev:1; classtype:attempted-admin;)
```
    
Rule ini memantau lalu lintas ke port 22 yang mengandung protokol "SSH-" dan memberikan peringatan jika terdeteksi lebih dari 3 percobaan koneksi SSH baru dari sumber yang sama dalam waktu 30 detik.
    
3. Deteksi Data Exfiltration (Pencurian Data)
    
```
alert tcp $HOME_NET 80 -> $EXTERNAL_NET any (msg:"[ALERT] Indikasi Pencurian Data via HTTP (Exfiltration)"; flow:from_server,established; content:"HTTP/1."; content:"200 OK"; distance:0; sid:1003; rev:1; classtype:policy-violation;)
```
    
Rule ini mendeteksi respons sukses HTTP (`200 OK`) yang mengalir keluar **dari** Server Riset (`$HOME_NET`) **menuju** Mahasiswa (`$EXTERNAL_NET`), yang mengindikasikan keberhasilan pengunduhan file/data.

---

# Laporan Simulasi Penyerangan & Validasi Keamanan Jaringan

Dokumen ini berisi dokumentasi hasil pengujian keamanan (*Penetration Testing*) pada topologi infrastruktur jaringan yang telah dibangun. Pengujian dilakukan untuk memvalidasi efektivitas *Access Control List* (ACL) dan memantau dampak serangan terhadap server.

## 1. Skenario Pengujian: Port Scanning (Reconnaissance)

**Tujuan:** Memastikan bahwa aturan Firewall/ACL di Core Router berhasil menyembunyikan port sensitif (SSH) dari pengguna yang tidak berhak (Mahasiswa), namun tetap mengizinkan akses ke layanan publik (Web Server).

* **Attacker:** Mahasiswa (10.20.10.100)
* **Target:** Server Akademik (10.20.20.10)
* **Tools:** Nmap

### Hasil Pengujian
![Hasil Nmap](/Assets/Simulasi_Penyerangan/nmap_mhs_ke_akademik.png)

**Analisis:**
* **Port 22 (SSH) - `filtered`:** Paket permintaan koneksi berhasil dibuang (*DROP*) oleh Core Router sebelum mencapai server. Ini membuktikan segmentasi jaringan aman.
* **Port 80 (HTTP) - `open`:** Layanan web dapat diakses secara normal oleh mahasiswa sesuai kebijakan layanan publik.

---

## 2. Skenario Pengujian: Denial of Service (SYN Flood)

**Tujuan:** Menguji ketahanan jaringan dan memverifikasi bahwa lalu lintas serangan dapat dipantau melalui Core Router serta melihat dampaknya pada sisi server.

* **Attacker:** Mahasiswa
* **Target:** Server Akademik (Port 80)
* **Tools:** Hping3

### A. Pelaksanaan Serangan
Penyerang mengirimkan banjir paket SYN (*SYN Flood*) ke port 80 server akademik untuk memenuhi antrian koneksi server.

![Eksekusi Serangan](/Assets/Simulasi_Penyerangan/serangan_syn_flood.png)

### B. Monitoring Trafik di Core Router
Lonjakan trafik dapat diamati pada *counter* `iptables` di Core Router. Hal ini membuktikan bahwa administrator jaringan memiliki visibilitas terhadap anomali trafik yang terjadi. Bisa dilihat pada PKTS yang berjumlah 655K

![Monitoring Router](/Assets/Simulasi_Penyerangan/informasi_syn_flood_di_core_router.png)

### C. Dampak pada Server Target
Server mengalami kebanjiran permintaan koneksi palsu (*Half-open connections*). Terlihat banyaknya status `SYN_RECV` pada monitoring soket server, yang mengindikasikan server sedang menahan sumber daya untuk koneksi yang tidak pernah selesai (ciri khas serangan SYN Flood).

![Dampak Server 1](/Assets/Simulasi_Penyerangan/Informasi_syn_flood_di_server_akademik.png)

*(Detail status koneksi saat serangan berlangsung)*
![Dampak Server 2](/Assets/Simulasi_Penyerangan/efek_syn_flood.png)

---

## Kesimpulan Validasi Penyerangan

Berdasarkan pengujian di atas, disimpulkan bahwa:
1.  **Access Control List (ACL)** berfungsi dengan baik dalam membatasi akses ilegal (SSH) dari jaringan mahasiswa.
2.  **Visibilitas Jaringan** terpenuhi, dimana lonjakan trafik akibat serangan dapat dipantau melalui log router.
3.  **Sistem Pertahanan** berhasil memisahkan *traffic* manajemen (Admin) dari *traffic* publik, sehingga meskipun layanan web diserang, akses manajemen router tetap aman.


## 3. Validasi Skalabilitas & High Availability (Load Balancing)

**Tujuan:**
Menguji kemampuan jaringan dalam menangani kolaborasi antar departemen dan skalabilitas layanan. Pengujian ini memverifikasi bahwa *Load Balancer* berfungsi mendistribusikan lalu lintas ke server yang berbeda (Riset & Smart City) melalui satu pintu masuk (*Single Point of Entry*).

* **Tester:** Admin Workstation (Akses Penuh)
* **Target:** Virtual IP Load Balancer (10.20.30.5)
* **Mekanisme:** Round Robin Distribution

### Hasil Pengujian
Pengujian dilakukan dengan mengirimkan permintaan HTTP (`curl`) secara berulang ke IP Load Balancer.

![Validasi Load Balancer](/Assets/Validasi_LoadBalancer.png)

**Analisis Hasil:**
Terlihat pada gambar di atas bahwa respon server berubah-ubah secara bergantian untuk setiap permintaan:
1.  **Request ke-1:** Dilayani oleh `Server RISET & IOT`.
2.  **Request ke-2:** Dilayani oleh `Server SMART CITY`.
3.  **Request ke-3:** Kembali dilayani oleh `Server RISET & IOT`.

**Kesimpulan:**
Sistem berhasil mengimplementasikan **High Availability**. Penambahan layanan baru (Smart City) berhasil dilakukan tanpa mengganggu infrastruktur utama, dan mekanisme *Load Balancing* efektif membagi beban lalu lintas, memudahkan akses data bagi departemen yang berkepentingan tanpa harus menghafal banyak IP server.

## 4. Validasi Keamanan Perimeter (Firewall Functionality)

**Tujuan:**
Memverifikasi fungsi utama Firewall sebagai garis pertahanan terdepan (*Perimeter Defense*). Pengujian ini bertujuan membuktikan bahwa Firewall mampu memblokir akses tidak sah yang berasal dari luar jaringan (Internet/Edge Router) menuju server internal, serta memastikan tidak ada kebocoran paket ke dalam jaringan lokal.

* **Attacker:** Edge Router (Simulasi Hacker/Orang Luar)
* **Target:** Server Akademik (10.20.20.10)
* **Tools:** Ping & Tcpdump (Network Forensics)

### A. Eksekusi Serangan dari Luar
Penyerang mencoba melakukan koneksi langsung (*Direct Ping*) ke server internal yang seharusnya tersembunyi di balik Firewall.

![Eksekusi Serangan](/Assets/Validasi_Firewall/Mencoba%20serang%20ke%20firewall%20langsung.png)

**Analisis:**
Terlihat hasil **100% Packet Loss**. Penyerang tidak mendapatkan balasan apapun dari target, menandakan jalur koneksi terputus.

### B. Analisis Forensik di Firewall
Untuk membuktikan bahwa paket benar-benar diblokir oleh Firewall (bukan karena routing error atau server mati), dilakukan pemantauan paket (*sniffing*) langsung di mesin Firewall menggunakan `tcpdump`.

![Forensik Firewall](/Assets/Validasi_Firewall/Capture_tcpdump_di_firewall.png)

**Analisis Bukti:**
Pada log `tcpdump` di atas terlihat fenomena penting:
* **`eth0 In`**: Paket ICMP Request dari penyerang (`192.168.1.1`) terdeteksi **MASUK** ke interface luar Firewall.
* **TIDAK ADA `eth1 Out`**: Tidak ada log paket yang diteruskan keluar menuju interface dalam.

**Kesimpulan:**
Firewall berfungsi sempurna. Paket serangan diterima, dianalisis, dan langsung **DIBUANG (DROPPED)** di tempat tanpa diteruskan ke jaringan internal. Hal ini membuktikan integritas keamanan perimeter terjaga dan tidak ada kebocoran lalu lintas (*traffic leak*).


## 5. Validasi Advanced Security (Intrusion Detection System)

**Tujuan:**
Mengimplementasikan sistem pertahanan tingkat lanjut menggunakan **Suricata IDS** yang ditempatkan secara strategis di **Core Router**. Pengujian ini bertujuan untuk memverifikasi kemampuan sistem dalam mendeteksi pola lalu lintas mencurigakan dari dalam jaringan (*Insider Threat*) dan memantau dampak serangan pada sisi server.

* **Detector:** Suricata IDS (Mode: *Network Intrusion Detection System*)
* **Lokasi Sensor:** Core Router (Interface `eth3` - Gateway Mahasiswa)
* **Attacker:** Mahasiswa (10.20.10.100)
* **Target:** Server Akademik (10.20.20.10)

### A. Deteksi Reconnaissance (Scanning)
Pada tahap awal serangan, penyerang biasanya melakukan pemindaian untuk mencari celah. IDS dikonfigurasi untuk mengenali pola pemindaian ini.

**Bukti Deteksi:**
Ketika Mahasiswa melakukan `nmap` ke Server Akademik, IDS di Core Router langsung mencatat aktivitas tersebut sebagai potensi ancaman.

![Log Deteksi Port Scan](/Assets/Simulasi_Penyerangan/nmap_mhs_ke_akademik.png)
*(Gambar: Hasil Nmap dari sisi penyerang menunjukkan port SSH tertutup, namun aktivitas ini tertangkap oleh IDS)*

**Analisis Teknis:**
* **Signature Match:** Rule Suricata `sid:1000002` (*Percobaan Koneksi SSH*) terpicu karena adanya paket TCP SYN yang menuju ke port 22, meskipun koneksi tersebut akhirnya diblokir oleh ACL Router. Ini membuktikan IDS bekerja mendeteksi niat jahat sebelum blokir terjadi.

---

### B. Deteksi Serangan Denial of Service (SYN Flood)
Penyerang melancarkan serangan banjir paket (*SYN Flood*) menggunakan `hping3` untuk melumpuhkan layanan web akademik.

**Bukti Deteksi di Core Router:**
Log IDS menunjukkan lonjakan peringatan (*alert*) yang masif dalam waktu singkat, menandakan adanya anomali lalu lintas.

![Log Core IDS Attack](/Assets/Simulasi_Penyerangan/log_core_router.png)

**Analisis Teknis:**
* **Traffic Anomaly:** Log `CORE IDS: Akses Web Server Detected` muncul berulang kali dengan *timestamp* yang hampir bersamaan (milidetik).
* **Threshold Trigger:** Rule deteksi DDoS (`sid:1000004`) mendeteksi volume paket SYN yang melebihi ambang batas wajar (*threshold*) dari satu alamat IP sumber (`10.20.10.100`) menuju satu tujuan (`10.20.20.10`).

---

### C. Dampak pada Sistem Target (Server Akademik)
Serangan DDoS yang lolos dari ACL (karena menuju port 80 yang diizinkan) akan membebani server target.

**Bukti Log Sistem Server:**
Kernel Linux pada Server Akademik mendeteksi kebanjiran permintaan koneksi dan mengaktifkan mekanisme pertahanan diri.

![Log Kernel Server](/Assets/Simulasi_Penyerangan/serangan_syn_flood.png)
*(Gambar: Pesan "Possible SYN flooding on port 80" pada terminal Server Akademik)*

**Analisis Dampak:**
* **Resource Exhaustion:** Pesan log tersebut muncul karena *backlog queue* untuk koneksi TCP pada server telah penuh.
* **Mitigasi Otomatis:** Sistem operasi secara otomatis mengaktifkan **TCP SYN Cookies**. Ini adalah mekanisme pertahanan di mana server tidak lagi mengalokasikan memori untuk menyimpan status koneksi setengah terbuka (*half-open*), melainkan mengenkripsi informasi koneksi ke dalam *sequence number* (cookie) untuk mencegah server *crash* akibat kehabisan memori.

---

## 6. Kesimpulan Akhir & Evaluasi Sistem

Berdasarkan seluruh rangkaian pengujian, berikut adalah evaluasi akhir terhadap sistem keamanan jaringan yang telah dibangun:

| Komponen | Fungsi Utama | Status Validasi | Keterangan |
| :--- | :--- | :--- | :--- |
| **Firewall (Edge)** | Perimeter Security & NAT | ✅ **BERHASIL** | Berhasil memblokir serangan ping dari luar (Edge Router) dan menyembunyikan IP internal (NAT Masquerade). |
| **ACL (Core Router)** | Internal Segmentation | ✅ **BERHASIL** | Berhasil memblokir akses Mahasiswa ke Admin & Riset (True Negative) namun tetap mengizinkan akses Web Akademik (True Positive). |
| **Load Balancer** | High Availability | ✅ **BERHASIL** | Trafik Web Riset terbagi rata (*Round Robin*) antara Server Riset dan Server Smart City, meningkatkan ketersediaan layanan. |
| **IDS (Suricata)** | Detection & Visibility | ✅ **BERHASIL** | Mampu mendeteksi serangan *scanning* dan DDoS secara *real-time*, memberikan visibilitas penuh kepada administrator terhadap ancaman internal. |
| **DHCP Server** | Dynamic Addressing | ✅ **BERHASIL** | Manajemen IP otomatis berjalan lancar untuk klien dinamis (Mahasiswa & Guest). |

**Rekomendasi Pengembangan:**
Untuk pengembangan selanjutnya, sistem ini dapat ditingkatkan dengan mengintegrasikan Suricata dalam mode **IPS (Intrusion Prevention System)** agar dapat memblokir serangan DDoS secara otomatis tanpa intervensi manual, serta menggunakan **SIEM (Security Information and Event Management)** untuk sentralisasi log dari Firewall dan Core Router.
