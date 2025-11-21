# Laporan Tugas Akhir - ITS Secure Network Challenge

**Mata Kuliah:** Keamanan Jaringan Komputer  
**Departemen:** Teknologi Informasi - ITS  
**Kelas:** C - Kelompok 1

## Anggota Kelompok

| Nama | NRP |
| :--- | :--- |
| Syela Zeruya Tandi Lalong | 5027231076 |
| Tasya Aulia Darmawan | 5027241009 |
| Azaria Raissa Maulidinnisa | 5027241043 |
| M. Hikari Reiziq Rakhmadinta | 5027241079 |
| Ni'mah Fauziyyah Atok | 5027241103 |

---

## Desain Topologi Jaringan

Berikut adalah desain akhir infrastruktur jaringan yang telah kami implementasikan. Topologi ini dirancang menggunakan prinsip **Defense in Depth** (Pertahanan Berlapis) dan **Modularitas** untuk menjamin keamanan, ketersediaan, dan kemudahan pengembangan.

![Topologi Jaringan](/Assets/topologi.png)

### Komponen Utama Topologi:
1.  **Perimeter Security (Edge & Firewall):** Melindungi jaringan kampus dari ancaman eksternal dan menangani lalu lintas keluar-masuk internet (NAT).
2.  **Internal Security (Core Router ACL):** Menerapkan segmentasi jaringan yang ketat antar departemen (Mahasiswa, Admin, Riset, Guest) untuk mencegah pergerakan lateral serangan.
3.  **High Availability (Load Balancer):** Menggunakan Nginx Load Balancer pada subnet Riset untuk mendistribusikan beban lalu lintas ke Server Riset dan Server Smart City.
4.  **Dynamic Addressing:** Implementasi DHCP Server pada Core Router untuk manajemen IP otomatis pada subnet publik (Mahasiswa & Guest).

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