# Panduan Pengujian - FINANCE PRO

Dokumen ini berisi skenario pengujian menyeluruh untuk memverifikasi semua modul aplikasi FINANCE PRO berfungsi dengan benar sebelum produksi.

---

## Daftar Isi

1. [Persiapan Pengujian](#persiapan-pengujian)
2. [Pengujian Fungsional](#pengujian-fungsional)
3. [Pengujian Akuntansi](#pengujian-akuntansi)
4. [Pengujian Keamanan](#pengujian-keamanan)
5. [Pengujian Edge Cases](#pengujian-edge-cases)
6. [Pengujian Performance](#pengujian-performance)
7. [Checklist Akhir](#checklist-akhir)

---

## Persiapan Pengujian

### Environment
- Browser modern (Chrome 100+, Firefox 100+, Edge, Safari)
- Resolusi: minimum 1280×720 (desktop), 375×812 (mobile)
- Internet connection (untuk CDN Bootstrap, Font Awesome, Chart.js)

### Setup Data
- Pastikan file `finance-pro.html` dapat dibuka di browser
- Atau serve via HTTP: `python3 -m http.server 8080`
- Buka URL → pastikan halaman login muncul

---

## Pengujian Fungsional

### 1. Login & Logout

| # | Skenario | Langkah | Expected Result | Status |
|---|----------|--------|----------------|--------|
| 1.1 | Login dengan kredensial valid | Email `admin@financepro.id`, password `admin123`, klik "Masuk" | Redirect ke dashboard, toast "Selamat Datang" muncul | ☐ |
| 1.2 | Login dengan email salah | Email `salah@financepro.id`, password `admin123` | Toast error "Email atau kata sandi salah" | ☐ |
| 1.3 | Login dengan password salah | Email valid, password `salah` | Toast error muncul | ☐ |
| 1.4 | Quick login chip | Klik chip "Bendahara" | Form terisi otomatis, login berhasil sebagai Bendahara | ☐ |
| 1.5 | Logout | Klik avatar → "Keluar" | Kembali ke halaman login | ☐ |
| 1.6 | Session persist (Ingat saya) | Centang "Ingat saya", refresh halaman | Tetap login | ☐ |

### 2. Navigasi & UI

| # | Skenario | Langkah | Expected Result | Status |
|---|----------|--------|----------------|--------|
| 2.1 | Navigasi sidebar | Klik setiap menu di sidebar | Halaman berganti, judul & breadcrumb update | ☐ |
| 2.2 | Highlight active menu | Buka "Pemasukan" | Menu "Pemasukan" di sidebar aktif (background teal) | ☐ |
| 2.3 | Global search | Ketik "anggaran" di topbar search, tekan Enter | Pindah ke halaman Anggaran | ☐ |
| 2.4 | Notifikasi badge | Cek badge merah di "Persetujuan" | Jumlah pengajuan pending terlihat | ☐ |
| 2.5 | Mobile responsive | Resize ke 375px | Sidebar collapse, menu hamburger muncul | ☐ |
| 2.6 | Toggle sidebar (mobile) | Klik hamburger | Sidebar slide-in dari kiri | ☐ |

### 3. Master Data Organisasi

| # | Skenario | Langkah | Expected Result | Status |
|---|----------|--------|----------------|--------|
| 3.1 | Lihat profil organisasi | Buka menu Organisasi | Form terisi data Yayasan Nur Hidayah | ☐ |
| 3.2 | Edit organisasi | Ubah nama, klik "Simpan" | Toast "Berhasil", data tersimpan | ☐ |
| 3.3 | Lihat struktur organisasi | Buka "Struktur & Unit" | Tree struktur (Direktorat → Departemen) terlihat | ☐ |
| 3.4 | Tambah unit baru | Klik "Tambah Unit", isi form, simpan | Unit baru muncul di tree & tabel | ☐ |
| 3.5 | Edit unit | Klik icon edit di tabel unit, ubah, simpan | Data terupdate | ☐ |
| 3.6 | Hapus unit | Klik icon hapus, konfirmasi | Unit hilang dari daftar | ☐ |

### 4. Chart of Accounts (COA)

| # | Skenario | Langkah | Expected Result | Status |
|---|----------|--------|----------------|--------|
| 4.1 | Lihat COA | Buka menu COA | 5 kelompok akun terlihat, 32 akun terdaftar | ☐ |
| 4.2 | Tambah akun | Klik "Tambah Akun", isi kode 5700 "Beban Asuransi", simpan | Akun baru muncul di kelompok Beban | ☐ |
| 4.3 | Validasi kode unik | Tambah akun dengan kode 1100 (sudah ada) | Toast error "Kode akun sudah ada" | ☐ |
| 4.4 | Nonaktifkan akun | Klik icon toggle di akun | Status berubah jadi "Nonaktif" | ☐ |
| 4.5 | Edit akun | Edit nama akun, simpan | Nama berubah | ☐ |

### 5. Kas & Bank

| # | Skenario | Langkah | Expected Result | Status |
|---|----------|--------|----------------|--------|
| 5.1 | Lihat daftar rekening | Buka menu Kas & Bank | 4 rekening terlihat (2 kas + 2 bank) | ☐ |
| 5.2 | Tambah rekening bank | Klik "Tambah Rekening", isi data, simpan | Rekening baru muncul | ☐ |
| 5.3 | Lihat mutasi rekening | Klik icon "Lihat Mutasi" di salah rekening | Modal muncul dengan daftar transaksi | ☐ |
| 5.4 | Edit saldo awal | Edit rekening, ubah saldo awal, simpan | Saldo berjalan terupdate | ☐ |

### 6. Anggaran

| # | Skenario | Langkah | Expected Result | Status |
|---|----------|--------|----------------|--------|
| 6.1 | Lihat daftar anggaran | Buka menu Anggaran | 7 anggaran terdaftar, semua status "Approved" | ☐ |
| 6.2 | Ajukan anggaran baru | Klik "Ajukan Anggaran", isi unit=SMP, volume=1, harga=100jt, simpan | Anggaran baru muncul dengan status "Submitted" | ☐ |
| 6.3 | Validasi total = volume × harga | Ubah volume/harga | Total otomatis terhitung | ☐ |
| 6.4 | Lihat detail anggaran | Klik icon mata di anggaran | Modal detail muncul dengan info realisasi | ☐ |
| 6.5 | Approve anggaran | Di detail modal, klik "Setujui" | Status berubah jadi "Approved" | ☐ |
| 6.6 | Revisi anggaran | Klik icon revisi, masukkan nilai baru | Anggaran terupdate, audit log tercatat | ☐ |
| 6.7 | Monitoring realisasi | Buka "Monitoring Realisasi" | Tabel & grafik per unit terlihat, status serapan jelas | ☐ |

### 7. Pemasukan (Income)

| # | Skenario | Langkah | Expected Result | Status |
|---|----------|--------|----------------|--------|
| 7.1 | Lihat daftar pemasukan | Buka menu Pemasukan | 8 transaksi terlihat, total posted terhitung | ☐ |
| 7.2 | Filter berdasarkan kategori | Pilih kategori "Donasi & Infaq" | Hanya transaksi donasi yang tampil | ☐ |
| 7.3 | Search transaksi | Ketik "SPP" di search box | Hanya transaksi SPP yang tampil | ☐ |
| 7.4 | Catat pemasukan baru | Klik "Catat Pemasukan", isi form lengkap, "Simpan & Posting" | Transaksi baru muncul, saldo kas/bank bertambah | ☐ |
| 7.5 | Simpan sebagai draft | Isi form, klik "Simpan Draft" | Status transaksi "Draft" | ☐ |
| 7.6 | Posting draft | Klik icon centang di transaksi draft | Status berubah "Posted", jurnal otomatis dibuat | ☐ |
| 7.7 | Lihat detail + jurnal | Klik icon mata | Modal detail muncul dengan tabel jurnal (debit=kredit) | ☐ |
| 7.8 | Validasi jurnal seimbang | Lihat detail transaksi posted | Total debit = total kredit | ☐ |

### 8. Pengeluaran (Expense) - Workflow Approval

| # | Skenario | Langkah | Expected Result | Status |
|---|----------|--------|----------------|--------|
| 8.1 | Lihat daftar pengajuan | Buka menu Pengeluaran | 11 transaksi dengan berbagai status | ☐ |
| 8.2 | Ajukan pengeluaran baru | Klik "Pengajuan Baru", isi form, "Ajukan" | Status "Submitted", muncul di Approval | ☐ |
| 8.3 | Validasi anggaran | Ajukan pengeluaran melebihi sisa anggaran | Modal konfirmasi "Melebihi sisa anggaran" | ☐ |
| 8.4 | Verifikasi pengajuan | Di menu Persetujuan, klik "Verifikasi" | Status berubah "Verified" | ☐ |
| 8.5 | Approve pengajuan | Klik "Setujui" di pengajuan verified | Status berubah "Approved" | ☐ |
| 8.6 | Pay pengajuan | Klik icon uang di pengajuan approved | Status berubah "Paid", saldo berkurang, jurnal dibuat | ☐ |
| 8.7 | Reject pengajuan | Klik "Tolak" | Status "Rejected" | ☐ |
| 8.8 | Cek workflow visual | Lihat modal detail pengeluaran | 4 step workflow terlihat dengan status jelas | ☐ |

### 9. Transfer Antar Rekening

| # | Skenario | Langkah | Expected Result | Status |
|---|----------|--------|----------------|--------|
| 9.1 | Lihat daftar transfer | Buka menu Transfer | 3 transfer terlihat | ☐ |
| 9.2 | Transfer baru | Klik "Transfer Baru", isi from/to/amount, proses | Saldo sumber berkurang, tujuan bertambah | ☐ |
| 9.3 | Validasi rekening sama | Pilih from = to | Toast error "Rekening asal dan tujuan tidak boleh sama" | ☐ |
| 9.4 | Validasi saldo cukup | Transfer melebihi saldo | Toast error "Saldo tidak cukup" | ☐ |
| 9.5 | Cek jurnal transfer | Lihat detail transfer | Jurnal: debit tujuan, kredit sumber (tidak ada pendapatan/beban) | ☐ |

---

## Pengujian Akuntansi

### 10. Jurnal Umum

| # | Skenario | Langkah | Expected Result | Status |
|---|----------|--------|----------------|--------|
| 10.1 | Lihat daftar jurnal | Buka menu Jurnal Umum | Semua jurnal terlihat, ada indikator balanced | ☐ |
| 10.2 | Buat jurnal manual | Klik "Jurnal Manual", isi 2 baris (debit=kredit), posting | Jurnal baru muncul dengan checkmark hijau | ☐ |
| 10.3 | Validasi jurnal tidak seimbang | Buat jurnal debit ≠ kredit, klik posting | Toast error "Total Debit harus = Total Kredit" | ☐ |
| 10.4 | Tambah baris jurnal | Klik "Tambah Baris" | Baris baru muncul, total terupdate | ☐ |
| 10.5 | Lihat detail jurnal | Klik icon mata | Modal dengan tabel debit/kredit per akun | ☐ |

### 11. Buku Besar

| # | Skenario | Langkah | Expected Result | Status |
|---|----------|--------|----------------|--------|
| 11.1 | Lihat buku besar | Buka menu Buku Besar | List akun dengan mutasi & saldo akhir | ☐ |
| 11.2 | Filter per akun | Pilih akun spesifik di dropdown | Hanya mutasi akun tersebut yang tampil | ☐ |
| 11.3 | Verifikasi running balance | Cek akun Kas Besar | Saldo akhir = saldo awal + (debit - kredit) | ☐ |

### 12. Neraca Saldo

| # | Skenario | Langkah | Expected Result | Status |
|---|----------|--------|----------------|--------|
| 12.1 | Lihat neraca saldo | Buka menu Neraca Saldo | Tabel semua akun dengan debit/kredit | ☐ |
| 12.2 | Validasi keseimbangan | Cek total debit vs kredit | Equal, alert "Neraca saldo seimbang" muncul | ☐ |
| 12.3 | Cetak neraca saldo | Klik "Cetak" | Dialog print browser muncul | ☐ |
| 12.4 | Export CSV | Klik "Export" | File CSV terdownload | ☐ |

### 13. Laporan Keuangan

| # | Skenario | Langkah | Expected Result | Status |
|---|----------|--------|----------------|--------|
| 13.1 | Lihat Neraca | Buka Laporan Keuangan → tab "Neraca" | Tabel Aset, Liabilitas & Ekuitas terlihat | ☐ |
| 13.2 | Validasi neraca seimbang | Cek Total Aset vs Total Liab+Ekuitas | Equal, alert sukses muncul | ☐ |
| 13.3 | Lihat Laba Rugi | Klik tab "Laba Rugi" | Pendapatan, Beban, Surplus/Defisit terlihat | ☐ |
| 13.4 | Lihat Arus Kas | Klik tab "Arus Kas" | Aktivitas Operasi/Investasi/Pendanaan | ☐ |
| 13.5 | Lihat Perubahan Ekuitas | Klik tab "Perubahan Ekuitas" | Saldo awal, surplus, donasi, saldo akhir | ☐ |
| 13.6 | Cetak laporan | Klik "Cetak" | Print preview muncul dengan layout bersih | ☐ |

---

## Pengujian Keamanan

### 14. RBAC & Role

| # | Skenario | Langkah | Expected Result | Status |
|---|----------|--------|----------------|--------|
| 14.1 | Login sebagai Auditor | Quick login "Auditor" | Menu pengeluaran/pemasukan disembunyikan | ☐ |
| 14.2 | Auditor tidak bisa edit | Coba edit transaksi | Tidak ada tombol edit (read-only) | ☐ |
| 14.3 | Login sebagai Kepala Unit | Quick login "Kepala Unit" | Hanya bisa ajukan, tidak bisa approve tingkat tinggi | ☐ |
| 14.4 | Bendahara akses kas | Login Bendahara | Bisa catat pemasukan & pembayaran | ☐ |
| 14.5 | Logout otomatis | Tunggu session expire | Kembali ke halaman login | ☐ |

### 15. Audit Trail

| # | Skenario | Langkah | Expected Result | Status |
|---|----------|--------|----------------|--------|
| 15.1 | Lihat audit trail | Buka menu Audit Trail | Timeline aktivitas terlihat | ☐ |
| 15.2 | Verifikasi log login | Login baru, refresh audit trail | Entry "Login" baru muncul di paling atas | ☐ |
| 15.3 | Verifikasi log transaksi | Buat pengeluaran baru | Audit log "Tambah Pengeluaran" tercatat | ☐ |
| 15.4 | Verifikasi log approval | Approve sebuah anggaran | Audit log "Approval Anggaran" tercatat | ☐ |
| 15.5 | Log immutable | (SQL only) Coba UPDATE audit_logs | Error "audit_logs is append-only" | ☐ |

---

## Pengujian Edge Cases

### 16. Skenario Error

| # | Skenario | Langkah | Expected Result | Status |
|---|----------|--------|----------------|--------|
| 16.1 | Form kosong | Submit form tanpa isi field required | Toast error "X wajib diisi" | ☐ |
| 16.2 | Jumlah negatif | Input amount = -1000 | Tidak bisa submit / validasi gagal | ☐ |
| 16.3 | Jumlah 0 | Input amount = 0 | Toast error "Jumlah harus > 0" | ☐ |
| 16.4 | Tanggal masa depan | Input tanggal tahun 2099 | (Sesuai kebijakan - diterima/ditolak) | ☐ |
| 16.5 | Kode COA duplikat | Tambah akun dengan kode existing | Toast error | ☐ |
| 16.6 | Hapus data terkait | Hapus departemen yang punya transaksi | (Sesuai kebijakan - cascade atau tolak) | ☐ |

### 17. Skenario Akuntansi

| # | Skenario | Langkah | Expected Result | Status |
|---|----------|--------|----------------|--------|
| 17.1 | Jurnal tidak seimbang | Buat jurnal debit 100k, kredit 90k | Tolak posting | ☐ |
| 17.2 | Jurnal 1 baris saja | Buat jurnal hanya 1 baris | Tolak (min 2 baris) | ☐ |
| 17.3 | Posting ke periode tertutup | (SQL) Tutup periode, coba posting | Error "Periode sudah ditutup" | ☐ |
| 17.4 | Transfer ke rekening sama | Pilih from = to | Tolak dengan error | ☐ |
| 17.5 | Pembayaran melebihi piutang | Bayar piutang lebih dari sisa | Auto-clamp ke nilai maksimum | ☐ |
| 17.6 | Pengeluaran melebihi anggaran | Ajukan > sisa anggaran | Modal konfirmasi khusus | ☐ |
| 17.7 | Saldo kas negatif | Bayar pengeluaran melebihi saldo | Tolak "Saldo tidak cukup" | ☐ |

### 18. Konkurensi (SQL Level)

| # | Skenario | Langkah | Expected Result | Status |
|---|----------|--------|----------------|--------|
| 18.1 | Generate doc number concurrent | (SQL) 2 transaksi bersamaan panggil next_doc_number | Dapat nomor berbeda (atomic) | ☐ |
| 18.2 | Posting jurnal concurrent | 2 user posting jurnal bersamaan | Keduanya berhasil, no deadlock | ☐ |
| 18.3 | Update saldo kas concurrent | 2 pembayaran concurrent dari rekening sama | Saldo konsisten (atomic via function) | ☐ |

---

## Pengujian Performance

### 19. Load Testing

| # | Skenario | Expected Result | Status |
|---|----------|----------------|--------|
| 19.1 | Dashboard load time | < 2 detik di koneksi 4G | ☐ |
| 19.2 | Tabel 1000 baris | Render < 1 detik (perlu pagination di produksi) | ☐ |
| 19.3 | Chart render | < 500ms | ☐ |
| 19.4 | Search/filter | < 200ms response | ☐ |
| 19.5 | Export CSV 1000 baris | < 3 detik | ☐ |

### 20. Browser Compatibility

| Browser | Versi | Status |
|---------|-------|--------|
| Chrome | 100+ | ☐ |
| Firefox | 100+ | ☐ |
| Safari | 15+ | ☐ |
| Edge | 100+ | ☐ |
| Mobile Chrome | Android 10+ | ☐ |
| Mobile Safari | iOS 15+ | ☐ |

---

## Checklist Akhir

Sebelum deployment ke produksi, pastikan:

- [ ] Semua pengujian fungsional lulus (1-9)
- [ ] Semua pengujian akuntansi lulus (10-13)
- [ ] Semua pengujian keamanan lulus (14-15)
- [ ] Semua edge cases ditangani (16-18)
- [ ] Performance acceptable (19)
- [ ] Browser compatibility OK (20)
- [ ] RLS policies aktif di Supabase
- [ ] Audit trail berfungsi
- [ ] Backup database terjadwal
- [ ] SSL/HTTPS aktif
- [ ] API keys di Edge Function secrets (BUKAN frontend)
- [ ] Rate limiting di Edge Functions
- [ ] Error monitoring (Sentry/recommended)
- [ ] User acceptance testing (UAT) selesai
- [ ] Dokumentasi user telah dibagikan

---

## Reporting Bug

Jika menemukan bug saat pengujian:

1. Catat langkah reproduksi
2. Screenshot / record video
3. Catat browser, OS, dan versi
4. Catat expected vs actual result
5. Submit ke issue tracker

---

**Selamat menguji! Pastikan semua checklist dicentang sebelum go-live.**
