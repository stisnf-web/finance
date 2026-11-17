# Panduan Penggunaan - FINANCE PRO

Panduan untuk pengguna akhir aplikasi FINANCE & ACCOUNTING MANAGEMENT SYSTEM PRO.

---

## Daftar Isi

1. [Memulai](#memulai)
2. [Dashboard Keuangan](#dashboard-keuangan)
3. [Master Data](#master-data)
4. [Anggaran](#anggaran)
5. [Transaksi Harian](#transaksi-harian)
6. [Akuntansi](#akuntansi)
7. [Laporan Keuangan](#laporan-keuangan)
8. [AI Assistant](#ai-assistant)
9. [Tips & Trik](#tips--trik)
10. [FAQ](#faq)

---

## Memulai

### Login

1. Buka aplikasi di browser
2. Masukkan email dan kata sandi
3. Klik **Masuk ke Dashboard** atau gunakan quick login chip
4. Centang **Ingat saya** jika ingin tetap login

### Memahami Layout

```
┌─────────────┬────────────────────────────────────┐
│             │  Topbar (judul + search + profil) │
│  Sidebar    ├────────────────────────────────────┤
│  (navigasi) │                                    │
│             │       Konten Utama                 │
│             │       (kartu, tabel, grafik)       │
│             │                                    │
└─────────────┴────────────────────────────────────┘
                                    [AI FAB] 
```

- **Sidebar**: Navigasi semua modul
- **Topbar**: Pencarian global, notifikasi, profil
- **Konten**: Berubah sesuai modul yang dipilih
- **AI FAB**: Tombol mengambang AI Assistant (kanan bawah)

---

## Dashboard Keuangan

Dashboard adalah halaman utama yang menampilkan ringkasan keuangan real-time.

### KPI Cards (8 kartu)

| Kartu | Deskripsi |
|-------|-----------|
| Total Anggaran | Total anggaran tahunan yang disetujui |
| Total Realisasi | Total yang sudah terealisasi |
| Sisa Anggaran | Sisa anggaran yang belum direalisasi |
| Total Pemasukan | Akumulasi pemasukan posted |
| Total Pengeluaran | Akumulasi pengeluaran paid |
| Saldo Kas & Bank | Total likuiditas organisasi |
| Piutang Outstanding | Tagihan belum tertagih |
| Utang Outstanding | Invoice belum dibayar |

### Grafik

1. **Pemasukan vs Pengeluaran Bulanan**: Bar chart 12 bulan
2. **Anggaran vs Realisasi per Unit**: Horizontal bar chart
3. **Distribusi Pengeluaran per Kategori**: Doughnut chart
4. **Saldo Kas & Bank**: Pie chart distribusi rekening
5. **Penyerapan Anggaran**: Gauge chart persentase serapan

### Dashboard Pimpinan

- Unit dengan serapan tertinggi/terendah
- Jumlah pengajuan menunggu persetujuan
- Unit dengan anggaran hampir habis (≥85%)
- Tabel monitoring anggaran per unit dengan progress bar

### Notifikasi

Di pojok kanan atas, klik icon 🔔 untuk melihat:
- Pengajuan menunggu approval
- Anggaran mendekati batas
- Aktivitas penting lainnya

---

## Master Data

### Profil Organisasi

1. Buka **Master Data → Organisasi**
2. Edit informasi:
   - Nama, alamat, telepon, email
   - NPWP, pimpinan, tahun berdiri
   - Tahun buku, mata uang, metode pencatatan
3. Klik **Simpan Perubahan**

### Struktur Organisasi

1. Buka **Master Data → Struktur & Unit**
2. Lihat tree struktur di sebelah kiri
3. Tambah unit baru: klik **Tambah Unit**
4. Pilih parent (induk) unit
5. Set level (1=Direktorat, 2=Departemen, 3=Unit)

### Chart of Accounts (COA)

1. Buka **Master Data → Chart of Accounts**
2. COA dikelompokkan 5 tipe:
   - **1xxx ASET**: kas, bank, piutang, aset tetap
   - **2xxx LIABILITAS**: utang
   - **3xxx EKUITAS**: saldo dana, perubahan aset neto
   - **4xxx PENDAPATAN**: operasional, usaha, donasi
   - **5xxx BEBAN**: gaji, operasional, pendidikan, dll
3. Tambah akun baru: klik **Tambah Akun**
4. Nonaktifkan (bukan hapus) akun yang tidak terpakai

### Kas & Bank

1. Buka **Master Data → Kas & Bank**
2. Lihat saldo per rekening
3. Klik icon **list** untuk lihat mutasi rekening
4. Tambah rekening: klik **Tambah Rekening**

---

## Anggaran

### Penyusunan Anggaran

1. Buka **Anggaran → Perencanaan Anggaran**
2. Klik **Ajukan Anggaran**
3. Isi form:
   - **Unit Kerja**: pilih departemen
   - **Tahun Anggaran**: 2026
   - **Uraian**: deskripsi kebutuhan
   - **Volume × Harga Satuan**: otomatis hitung total
   - **Penanggung Jawab**: PIC anggaran
   - **Status**: Draft atau Submitted
4. Klik **Simpan Anggaran**

### Workflow Anggaran

```
Draft → Submitted → Review → Approved → (Locked)
                 ↓
              Rejected
                 ↓
              Revision
```

### Monitoring Realisasi

1. Buka **Anggaran → Monitoring Realisasi**
2. Lihat tabel per unit:
   - Anggaran disetujui
   - Realisasi (otomatis dari pengeluaran paid)
   - Sisa anggaran
   - Persentase serapan
3. Status indikator:
   - 🟢 **Aman**: serapan < 50%
   - 🟡 **Perlu Diperhatikan**: serapan 50-85%
   - 🟠 **Mendekati Batas**: serapan 85-100%
   - 🔴 **Melebihi**: serapan ≥ 100%

### Revisi Anggaran

1. Di daftar anggaran, klik icon **history** di anggaran approved
2. Masukkan nilai baru
3. Sistem mencatat audit trail "Revisi Anggaran"

---

## Transaksi Harian

### Mencatat Pemasukan

1. Buka **Transaksi → Pemasukan**
2. Klik **Catat Pemasukan**
3. Isi form:
   - **Tanggal**: tanggal penerimaan
   - **Sumber Dana**: dari siapa (siswa, donatur, vendor)
   - **Kategori**: SPP, Donasi, Pendapatan Usaha, dll
   - **Akun Penerima**: kas/bank yang menerima
   - **Metode**: tunai, transfer, VA, payment gateway
   - **Jumlah**: nominal (positif)
   - **Keterangan**: deskripsi
4. Pilih:
   - **Simpan Draft**: simpan tanpa posting jurnal
   - **Simpan & Posting**: langsung posting + buat jurnal otomatis

### Mengajukan Pengeluaran

1. Buka **Transaksi → Pengeluaran**
2. Klik **Pengajuan Baru**
3. Isi form:
   - **Unit Kerja**: departemen pengaju
   - **Kategori Biaya**: gaji, operasional, pendidikan, dll
   - **Akun Pembayaran**: kas/bank yang akan dibayar
   - **Jumlah**: nominal
   - **Uraian Kebutuhan**: detail keperluan
4. Klik **Ajukan**

### Workflow Persetujuan Pengeluaran

```
1. Submitted (Diajukan)
   ↓ Verifikasi oleh Manajer Keuangan
2. Verified (Diverifikasi)
   ↓ Approval oleh Direktur/Ketua (sesuai nominal)
3. Approved (Disetujui)
   ↓ Pembayaran oleh Bendahara
4. Paid (Dibayar) → Jurnal otomatis diposting
```

**Tombol aksi berubah sesuai status:**
- Status Submitted → tombol **Verifikasi**
- Status Verified → tombol **Setujui**
- Status Approved → tombol **Bayar** (icon uang)

### Transfer Antar Rekening

1. Buka **Transaksi → Transfer Antar Rekening**
2. Klik **Transfer Baru**
3. Pilih:
   - **Dari Rekening**: sumber dana
   - **Ke Rekening**: tujuan
   - **Jumlah**: nominal
4. Klik **Proses Transfer**

**Penting:** Transfer internal TIDAK dihitung sebagai pendapatan/pengeluaran baru. Hanya memindahkan saldo antar akun.

### Persetujuan (Approval)

1. Buka **Workflow → Persetujuan**
2. Lihat daftar pengajuan menunggu:
   - Tab **Pengeluaran**: pengajuan pengeluaran
   - Tab **Anggaran**: pengajuan anggaran
3. Klik tombol aksi:
   - **Verifikasi / Setujui**: lanjut ke step berikutnya
   - **Tolak**: reject pengajuan

---

## Akuntansi

### Jurnal Umum

1. Buka **Akuntansi → Jurnal Umum**
2. Lihat daftar jurnal dengan indikator balanced (✓ hijau)
3. Buat jurnal manual: klik **Jurnal Manual**
4. Isi:
   - Tanggal, Tipe Jurnal, Uraian
   - Tambah baris akun (min 2 baris)
   - Pastikan **Total Debit = Total Kredit**
5. Klik **Posting Jurnal**

**Aturan double-entry:**
- Setiap jurnal harus balanced (Debit = Kredit)
- Setiap baris hanya boleh punya debit ATAU kredit (tidak keduanya)
- Minimal 2 baris per jurnal

### Buku Besar

1. Buka **Akuntansi → Buku Besar**
2. Pilih akun di dropdown untuk filter
3. Lihat:
   - Saldo awal
   - Setiap mutasi (debit/kredit)
   - Running balance
   - Saldo akhir

### Neraca Saldo

1. Buka **Akuntansi → Neraca Saldo**
2. Lihat semua akun dengan saldo debit/kredit
3. Validasi: Total Debit harus = Total Kredit (alert hijau)

### Rekonsiliasi Bank

1. Buka **Akuntansi → Rekonsiliasi Bank**
2. Lihat saldo buku vs saldo bank per rekening
3. Identifikasi selisih
4. Import mutasi bank CSV: klik **Import CSV**

---

## Laporan Keuangan

### Laporan Utama

Buka **Pelaporan → Laporan Keuangan**, pilih tab:

#### Neraca (Laporan Posisi Keuangan)
- Aset (kiri) vs Liabilitas & Ekuitas (kanan)
- Harus seimbang: Total Aset = Total Liab + Ekuitas

#### Laba Rugi (Laporan Aktivitas)
- Pendapatan - Beban = Surplus/Defisit
- Berguna untuk evaluasi kinerja

#### Arus Kas
- Operasi: penerimaan & pembayaran harian
- Investasi: pembelian aset
- Pendanaan: modal & pinjaman

#### Perubahan Ekuitas
- Saldo awal + surplus + donasi = Saldo akhir

### Export & Print

- **Export Excel/CSV**: klik tombol Export di setiap modul
- **Print/PDF**: klik tombol Cetak (icon printer) → dialog print browser → Save as PDF

---

## AI Assistant

AI Financial Assistant membantu menganalisis keuangan tanpa harus membuka banyak laporan.

### Mengaktifkan AI

1. Klik tombol **robot** mengambang di kanan bawah
2. Atau buka **Utama → AI Assistant** di sidebar

### Pertanyaan yang Bisa Diajukan

**Analisis Anggaran:**
- "Berapa total realisasi anggaran semua unit bulan ini?"
- "Unit mana yang penyerapan anggarannya paling tinggi?"
- "Apa penyebab deviasi anggaran terbesar?"

**Posisi Keuangan:**
- "Bagaimana posisi kas dan bank saat ini?"
- "Berapa total pengeluaran operasional?"
- "Berapa sisa anggaran pendidikan?"

**Analisis & Rekomendasi:**
- "Buatkan narasi laporan keuangan singkat"
- "Rekomendasi efisiensi biaya"
- "Bagaimana tren pemasukan vs pengeluaran?"

**Klasifikasi:**
- "Klasifikasi transaksi ini ke COA mana: [deskripsi]"

### Batasan AI

⚠️ **AI TIDAK BISA:**
- Mengesahkan transaksi
- Memposting jurnal
- Mengubah anggaran
- Melakukan pembayaran
- Mengakses data di luar izin user

AI hanya memberikan analisis dan rekomendasi. Keputusan final tetap di tangan manusia.

---

## Tips & Trik

### Produktivitas

1. **Quick Login**: Klik chip role di halaman login untuk auto-fill
2. **Global Search**: Ketik di topbar search, tekan Enter untuk navigasi cepat
3. **Filter & Search**: Setiap tabel punya filter (status, kategori, unit) dan search box
4. **Export CSV**: Semua modul bisa export ke CSV/Excel untuk analisis lanjutan
5. **Print**: Tombol Cetak tersedia di laporan utama (Neraca Saldo, Laporan Keuangan)

### Best Practices

1. **Posting segera**: Jangan biarkan transaksi terlalu lama di status Draft
2. **Verify bukti**: Selalu upload bukti transaksi sebelum posting
3. **Review anggaran**: Cek Monitoring Realisasi minimal seminggu sekali
4. **Backup rutin**: Export backup JSON di Settings secara berkala
5. **Audit trail**: Cek Audit Trail untuk monitor aktivitas tim

### Keyboard Shortcuts (planned)

- `Alt + D`: ke Dashboard
- `Alt + I`: ke Pemasukan
- `Alt + E`: ke Pengeluaran
- `Alt + J`: ke Jurnal
- `Alt + R`: ke Laporan
- `Esc`: tutup modal

---

## FAQ

### Q: Bagaimana cara mengganti password user?

**A:** Untuk demo mode, edit di Settings → Manajemen Pengguna (akan datang). Untuk produksi (Supabase), gunakan menu "Lupa sandi?" di halaman login.

### Q: Apakah data tersimpan aman?

**A:** Ya. Pada demo mode, data tersimpan di browser Anda (localStorage). Pada produksi (Supabase), data tersimpan di PostgreSQL dengan RLS, backup otomatis, dan enkripsi.

### Q: Bisakah saya menghapus transaksi yang sudah diposting?

**A:** **Tidak.** Sesuai prinsip akuntansi, transaksi yang sudah diposting tidak boleh dihapus. Lakukan koreksi melalui **jurnal pembalik** (reversal journal).

### Q: Mengapa anggaran saya menunjukkan "Melebihi" (red)?

**A:** Realisasi sudah melebihi anggaran disetujui. Sistem akan mencegah pengajuan baru (dengan konfirmasi khusus). Ajukan revisi anggaran atau kurangi pengeluaran unit.

### Q: Bagaimana cara mengubah tahun buku?

**A:** Buka **Master Data → Organisasi**, ubah field "Tahun Buku". Pastikan juga membuat periode akuntansi baru untuk tahun tersebut.

### Q: Bisakah saya custom kategori pemasukan/pengeluaran?

**A:** Ya. Saat ini kategori hardcoded di data layer. Untuk produksi, tambahkan tabel `income_categories` dan `expense_categories` di Supabase (sudah disiapkan di schema).

### Q: Mengapa AI Assistant bilang "Mode demo aktif"?

**A:** API key AI (Gemini/OpenAI) belum dikonfigurasi. Lihat panduan deployment Section 3.3 untuk set secrets.

### Q: Bagaimana cara multi-organisasi?

**A:** Setiap user punya `organization_id` di profile. RLS akan otomatis filter data per org. Super Admin bisa lihat semua org.

### Q: Apakah aplikasi bisa offline?

**A:** Mode demo (localStorage) bisa offline setelah loaded. Mode produksi (Supabase) butuh internet.

### Q: Bisakah saya integrasi dengan aplikasi lain?

**A:** Ya, melalui:
- **Supabase REST API**: untuk GET/POST data
- **Edge Functions**: untuk logic custom
- **Webhooks** (planned): untuk event-driven integration

---

## Bantuan & Support

- 📖 Lihat [README.md](../README.md) untuk overview
- 🚀 Lihat [DEPLOYMENT.md](./DEPLOYMENT.md) untuk setup produksi
- 🧪 Lihat [TESTING.md](./TESTING.md) untuk skenario pengujian
- 🐛 Laporkan bug ke issue tracker
- 📧 Email: support@financepro.id

---

**Selamat menggunakan FINANCE PRO!** Semoga membantu transparansi dan akurasi keuangan organisasi Anda.
