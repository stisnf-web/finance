# FINANCE & ACCOUNTING MANAGEMENT SYSTEM PRO

> **Smart Finance – Transparent Budgeting – Accurate Accounting**
>
> Integrated Financial Management & Accounting Information System untuk Yayasan, Sekolah, Pesantren, Perusahaan, UMKM, Lembaga Sosial, dan Organisasi Nirlaba.

![Version](https://img.shields.io/badge/version-1.0.0-teal)
![License](https://img.shields.io/badge/license-MIT-navy)
![Status](https://img.shields.io/badge/status-production--ready-green)

---

## Daftar Isi

1. [Tentang Aplikasi](#tentang-aplikasi)
2. [Fitur Utama](#fitur-utama)
3. [Teknologi yang Digunakan](#teknologi-yang-digunakan)
4. [Struktur Proyek](#struktur-proyek)
5. [Quick Start (Demo Mode)](#quick-start-demo-mode)
6. [Deployment ke Supabase + Vercel](#deployment-ke-supabase--vercel)
7. [Akun Demo](#akun-demo)
8. [Keamanan](#keamanan)
9. [Roadmap](#roadmap)
10. [Dokumentasi Tambahan](#dokumentasi-tambahan)
11. [Lisensi](#lisensi)

---

## Tentang Aplikasi

**FINANCE PRO** adalah sistem terintegrasi yang mengelola seluruh siklus keuangan organisasi: mulai dari perencanaan anggaran, pengajuan dana, persetujuan, transaksi, pencatatan akuntansi double-entry, rekonsiliasi bank, sampai laporan keuangan otomatis.

**Prinsip utama sistem:**

1. Transparansi keuangan
2. Akuntabilitas transaksi
3. Akurasi pencatatan
4. Pengendalian anggaran
5. Efisiensi administrasi
6. Auditabilitas
7. Pelaporan real-time
8. Pengambilan keputusan berbasis data

---

## Fitur Utama

### Master Data
- Profil Organisasi (multi-tenant)
- Struktur Organisasi bertingkat (Direktorat → Departemen → Unit)
- Chart of Accounts (COA) 5 kelompok: Aset, Liabilitas, Ekuitas, Pendapatan, Beban
- Rekening Kas & Bank (multi-akun)
- Kategori Pemasukan & Pengeluaran
- Tahun Buku & Periode Akuntansi

### Anggaran
- Penyusunan anggaran tahunan per unit/program/kegiatan
- Workflow: Draft → Submitted → Review → Approved → Locked
- Formula: Total = Volume × Harga Satuan
- Monitoring realisasi dengan indikator status (Aman/Perlu Diperhatikan/Mendekati Batas/Melebihi)
- Revisi anggaran dengan audit trail

### Transaksi
- **Pemasukan**: kategori konfigurasi, multi-metode (cash/transfer/VA/gateway), auto-jurnal
- **Pengeluaran**: workflow 4-step (Submitted → Verified → Approved → Paid), validasi anggaran
- **Transfer Antar Rekening**: tidak dihitung sebagai pendapatan/pengeluaran baru
- **Approval Berjenjang**: configurable berdasarkan nominal & struktur organisasi

### Akuntansi Double-Entry
- Jurnal otomatis untuk setiap transaksi yang diposting
- Jurnal manual dengan validasi Debit = Kredit
- Buku Besar per akun dengan running balance
- Neraca Saldo otomatis dengan validasi keseimbangan
- Jurnal yang sudah diposting tidak dapat diedit (koreksi via jurnal pembalik)
- Penutupan periode akuntansi

### Laporan Keuangan
- Laporan Posisi Keuangan (Neraca)
- Laporan Aktivitas (Laba Rugi)
- Laporan Arus Kas
- Laporan Perubahan Aset Neto (Ekuitas)
- Neraca Saldo, Buku Besar, Jurnal Umum
- Laporan Anggaran vs Realisasi
- Laporan Piutang, Utang, Aset Tetap, Pajak
- Export PDF & Excel

### Modul Lanjutan
- **Piutang & Utang**: tracking jatuh tempo, umur piutang/utang, pelunasan
- **Aset Tetap**: database aset, penyusutan straight-line, jurnal penyusutan otomatis
- **Rekonsiliasi Bank**: import CSV mutasi, matching otomatis
- **Perpajakan**: PPh 21/23, PPN, PPh Final, generate bukti potong
- **Audit Trail**: log immutable semua aktivitas penting

### AI Financial Assistant
- Meringkas laporan keuangan
- Menganalisis realisasi anggaran & deviasi
- Proyeksi pengeluaran & tren kas
- Narasi laporan keuangan otomatis
- Rekomendasi efisiensi biaya
- Klasifikasi transaksi berdasarkan COA
- **AI tidak dapat melakukan aksi finansial** (approval, posting, payment)

### Dashboard Pimpinan
- KPI real-time: anggaran, realisasi, pemasukan, pengeluaran, kas/bank, piutang, utang
- Grafik interaktif (Chart.js)
- Unit dengan serapan tertinggi/terendah
- Pengajuan menunggu persetujuan
- Indikator anggaran hampir habis

---

## Teknologi yang Digunakan

### Frontend
- HTML5, CSS3, JavaScript ES6+
- Bootstrap 5 + CSS custom (palette Navy/Teal)
- Font Awesome 6 (icons)
- Chart.js 4 (grafik)

### Backend (Production)
- Supabase PostgreSQL 15
- Supabase Auth (JWT)
- Supabase Storage (bukti transaksi)
- Supabase Edge Functions (Deno)
- Row Level Security (RLS)

### AI Integration
- Google Gemini API (primary)
- OpenAI API (fallback)
- Edge Function sebagai proxy (API key di server-side)

### Deployment
- Frontend: Vercel
- Backend: Supabase Cloud
- Database: Supabase PostgreSQL

---

## Struktur Proyek

```
finance-pro/
├── index.html                    # Landing page (auto-redirect ke app)
├── public/                       # Static assets (Vercel serve)
│   ├── finance-pro.html          # Aplikasi utama (single-file HTML)
│   ├── supabase-client.js        # Supabase integration wrapper
│   └── finance-pro.config.json   # App manifest
├── supabase/                     # Backend (Supabase)
│   ├── schema.sql                # DDL lengkap (41 tabel)
│   ├── rls-policies.sql          # 43 Row Level Security policies
│   ├── seed.sql                  # Data demo
│   └── functions/                # Edge Functions (Deno)
│       ├── ai-assistant/         # AI Financial Assistant proxy
│       ├── post-journal/         # Atomic journal posting
│       ├── generate-doc-no/      # Document number generator
│       └── generate-financial-report/  # Report generator
├── docs/                         # Documentation
│   ├── DEPLOYMENT.md             # Panduan deployment Vercel
│   ├── TESTING.md                # Skenario pengujian
│   └── USER_GUIDE.md             # Panduan penggunaan
├── .github/workflows/            # CI/CD GitHub Actions
│   ├── validate.yml              # Validasi sintaks (JS/TS/SQL)
│   ├── deploy.yml                # Auto-deploy ke Vercel
│   └── supabase-migrate.yml      # Auto-migrate database
├── .vscode/extensions.json       # Recommended VSCode extensions
├── .env.example                  # Template environment variables
├── .gitignore                    # Git ignore rules
├── vercel.json                   # Vercel deployment config
├── package.json                  # Project metadata & scripts
├── README.md                     # Dokumentasi ini
├── CONTRIBUTING.md               # Panduan kontribusi
├── CHANGELOG.md                  # Riwayat perubahan
└── LICENSE                       # MIT License
```

---

## Quick Start (Demo Mode)

Aplikasi dapat langsung dijalankan **tanpa Supabase** untuk demo/testing:

### Opsi 1: Buka file langsung
```bash
# Buka public/finance-pro.html di browser, atau buka index.html di root untuk auto-redirect
open index.html
# atau
open public/finance-pro.html
```

### Opsi 2: Serve via HTTP (recommended)
```bash
# Clone repository
git clone https://github.com/YOUR-USERNAME/finance-pro.git
cd finance-pro

# Python
python3 -m http.server 8080
# Buka http://localhost:8080/ (auto-redirect ke app)

# Atau Node
npx serve . -p 8080
```

### Login Demo

| Role | Email | Password |
|------|-------|----------|
| Super Admin | `admin@financepro.id` | `admin123` |
| Ketua Yayasan | `ketua@financepro.id` | `ketua123` |
| Manajer Keuangan | `finance@financepro.id` | `finance123` |
| Staf Akuntansi | `akuntan@financepro.id` | `akuntan123` |
| Bendahara | `bendahara@financepro.id` | `bendahara123` |
| Kepala Unit | `kepala.smp@financepro.id` | `kepala123` |
| Auditor | `auditor@financepro.id` | `auditor123` |

> **Catatan:** Pada demo mode, data tersimpan di `localStorage` browser. Untuk produksi, gunakan Supabase (lihat [Deployment](#deployment-ke-supabase--vercel)).

---

## Deployment ke Supabase + Vercel

### Langkah 1: Setup Supabase Project

1. **Buat project** di [supabase.com](https://supabase.com) (free tier OK)
2. **Catat credentials** dari Dashboard → Settings → API:
   - Project URL
   - Anon Key (public)
   - Service Role Key (RAHASIA - jangan taruh di frontend!)

### Langkah 2: Jalankan SQL Schema

1. Buka Supabase Dashboard → **SQL Editor**
2. Jalankan file berikut secara berurutan:
   ```sql
   -- 1. Schema (DDL)
   \i supabase/schema.sql
   
   -- 2. RLS Policies
   \i supabase/rls-policies.sql
   
   -- 3. Seed Data
   \i supabase/seed.sql
   ```
   Atau copy-paste isi file satu per satu.

### Langkah 3: Setup Authentication

1. Di Supabase Dashboard → **Authentication** → **Users**
2. Buat 7 user demo (sesuai tabel di atas)
3. Set metadata saat create user:
   ```json
   {
     "name": "Admin Sistem",
     "role": "super_admin"
   }
   ```
4. Atau jalankan SQL setelah create user:
   ```sql
   INSERT INTO public.profiles (id, organization_id, email, name, role, active)
   SELECT
     u.id,
     'a0000001-0000-0000-0000-000000000001'::UUID,
     u.email,
     COALESCE(u.raw_user_meta_data->>'name', split_part(u.email,'@',1)),
     COALESCE(u.raw_user_meta_data->>'role', 'pengguna_unit'),
     TRUE
   FROM auth.users u
   WHERE NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = u.id);
   ```

### Langkah 4: Deploy Edge Functions

```bash
# Install Supabase CLI
npm i -g supabase

# Login & link project
supabase login
supabase link --project-ref your-project-ref

# Set secrets
supabase secrets set SUPABASE_URL=https://your-project.supabase.co
supabase secrets set SUPABASE_ANON_KEY=your-anon-key
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
supabase secrets set GEMINI_API_KEY=your-gemini-key
# atau
supabase secrets set OPENAI_API_KEY=your-openai-key

# Deploy semua functions
cd supabase/functions
supabase functions deploy ai-assistant
supabase functions deploy post-journal
supabase functions deploy generate-doc-no
supabase functions deploy generate-financial-report
```

### Langkah 5: Deploy Frontend ke Vercel

#### Opsi A: Vercel CLI
```bash
npm i -g vercel
vercel
# Ikuti prompt, set output directory ke folder root (.) yang berisi index.html + public/
```

#### Opsi B: Vercel Dashboard
1. Push repository ke GitHub
2. Import di [vercel.com](https://vercel.com)
3. Set Environment Variables:
   - `NEXT_PUBLIC_SUPABASE_URL` = URL Supabase
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY` = Anon Key
4. Deploy

### Langkah 6: Konfigurasi Integrasi

Edit `public/finance-pro.html`, ganti bagian `loadDB()` dan `saveDB()` dengan Supabase client:

```javascript
// Tambahkan di <head>
<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>

// Ganti loadDB/saveDB dengan Supabase client
const SUPABASE_URL = 'https://your-project.supabase.co';
const SUPABASE_KEY = 'your-anon-key';
const sb = window.supabase.createClient(SUPABASE_URL, SUPABASE_KEY);

// Contoh: load departments
async function loadDepartments() {
  const { data, error } = await sb.from('departments').select('*');
  if (error) { console.error(error); return []; }
  return data;
}
```

Lihat `docs/DEPLOYMENT.md` untuk panduan lengkap.

---

## Akun Demo & Hak Akses (RBAC)

| Role | Hak Akses |
|------|-----------|
| **Super Admin** | Akses penuh sistem, semua organisasi, konfigurasi |
| **Admin Organisasi** | Kelola organisasi, user, master data |
| **Ketua Yayasan** | Approval tingkat tinggi, lihat laporan konsolidasian |
| **Direktur** | Approval menengah, lihat data direktorat |
| **Manajer Keuangan** | Kelola semua transaksi, verifikasi, jurnal, laporan |
| **Staf Akuntansi** | Jurnal, COA, buku besar, laporan akuntansi |
| **Bendahara** | Kas, penerimaan, pembayaran |
| **Kepala Departemen** | Ajukan anggaran/pengeluaran untuk unitnya |
| **Kepala Unit** | Ajukan kebutuhan, lihat data unitnya |
| **Auditor** | Read-only semua data + audit trail |
| **Pengguna Unit** | Lihat data yang diizinkan, ajukan kebutuhan |

---

## Keamanan

### Prinsip yang Diterapkan

1. ✅ **Supabase Authentication** - JWT-based, email/password, magic link, OAuth
2. ✅ **Row Level Security (RLS)** - data isolation per organization
3. ✅ **Multi-tenant** - setiap tabel punya `organization_id`
4. ✅ **Role-Based Access Control** - 11 role dengan permission granular
5. ✅ **Audit Trail** - log immutable (trigger mencegah UPDATE/DELETE)
6. ✅ **Private Storage** - file upload via Supabase Storage dengan signed URL
7. ✅ **Input Validation** - database CHECK constraints + frontend validation
8. ✅ **XSS Protection** - Bootstrap escape + DOMPurify ready
9. ✅ **SQL Injection Protection** - parameterized queries via Supabase client
10. ✅ **Session Management** - JWT expiry + refresh token
11. ✅ **Encrypted Connection** - HTTPS/TLS via Supabase & Vercel
12. ✅ **Secret Management** - API key di Edge Function secrets, JANGAN di frontend
13. ✅ **Backup** - Supabase automatic daily backup + manual export JSON
14. ✅ **Segregation of Duties** - pembuat ≠ pemeriksa ≠ penyetuju ≠ pembayar

### Yang TIDAK Boleh Dilakukan

- ❌ Menaruh `service_role_key` atau API key AI di frontend
- ❌ Mengedit jurnal yang sudah diposting (gunakan jurnal pembalik)
- ❌ Menghapus transaksi yang sudah diposting
- ❌ Menonaktifkan RLS di tabel tenant
- ❌ Memberikan role `super_admin` ke user non-teknis

---

## Roadmap

- [x] Phase 1: Foundation (login, multi-tenant, RBAC)
- [x] Phase 2: Master Financial Data (COA, kas/bank, kategori)
- [x] Phase 3: Budget Management (planning, approval, monitoring)
- [x] Phase 4: Transaction Management (income, expense, transfer)
- [x] Phase 5: Accounting Engine (jurnal, buku besar, neraca saldo)
- [x] Phase 6: Financial Reporting (neraca, L/R, arus kas, ekuitas)
- [x] Phase 7: Advanced Finance (piutang, utang, aset, rekonsiliasi, pajak)
- [x] Phase 8: AI & Analytics (AI Assistant, dashboard pimpinan)
- [x] Phase 9: Testing & Deployment (SQL, RLS, Edge Functions, docs)
- [ ] Phase 10: Mobile App (React Native, planned Q2 2026)
- [ ] Phase 11: BI Dashboard (advanced analytics, planned Q3 2026)
- [ ] Phase 12: Multi-currency support (planned Q4 2026)

---

## Dokumentasi Tambahan

- 📖 [Panduan Deployment Vercel](docs/DEPLOYMENT.md)
- 🧪 [Skenario Pengujian](docs/TESTING.md)
- 👤 [Panduan Penggunaan](docs/USER_GUIDE.md)
- 🗄️ [SQL Schema](supabase/schema.sql)
- 🔒 [RLS Policies](supabase/rls-policies.sql)
- 🌱 [Seed Data](supabase/seed.sql)
- ⚡ [Edge Functions](supabase/functions/)

---

## Lisensi

MIT License - bebas digunakan untuk komersial & non-komersial.

---

## Kontak

- Issues: [GitHub Issues](https://github.com/your-repo/issues)
- Email: support@financepro.id

---

**Dibuat dengan prinsip:** _Smart Finance, Transparent Budgeting, Accurate Accounting._
