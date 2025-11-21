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
Lonjakan trafik dapat diamati pada *counter* `iptables` di Core Router. Hal ini membuktikan bahwa administrator jaringan memiliki visibilitas terhadap anomali trafik yang terjadi.

![Monitoring Router](/Assets/Simulasi_Penyerangan/informasi_syn_flood_di_core_router.png)

### C. Dampak pada Server Target
Server mengalami kebanjiran permintaan koneksi palsu (*Half-open connections*). Terlihat banyaknya status `SYN_RECV` pada monitoring soket server, yang mengindikasikan server sedang menahan sumber daya untuk koneksi yang tidak pernah selesai (ciri khas serangan SYN Flood).

![Dampak Server 1](/Assets/Simulasi_Penyerangan/Informasi_syn_flood_di_server_akademik.png)

*(Detail status koneksi saat serangan berlangsung)*
![Dampak Server 2](/Assets/Simulasi_Penyerangan/efek_syn_flood.png)

---

## Kesimpulan Validasi

Berdasarkan pengujian di atas, disimpulkan bahwa:
1.  **Access Control List (ACL)** berfungsi dengan baik dalam membatasi akses ilegal (SSH) dari jaringan mahasiswa.
2.  **Visibilitas Jaringan** terpenuhi, dimana lonjakan trafik akibat serangan dapat dipantau melalui log router.
3.  **Sistem Pertahanan** berhasil memisahkan *traffic* manajemen (Admin) dari *traffic* publik, sehingga meskipun layanan web diserang, akses manajemen router tetap aman.