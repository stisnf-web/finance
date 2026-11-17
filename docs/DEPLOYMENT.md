# Panduan Deployment - FINANCE PRO ke Vercel + Supabase

Panduan langkah-demi-langkah deployment aplikasi FINANCE PRO ke production menggunakan Vercel (frontend) + Supabase (backend).

---

## Daftar Isi

1. [Arsitektur Deployment](#arsitektur-deployment)
2. [Prasyarat](#prasyarat)
3. [Langkah 1: Setup Supabase](#langkah-1-setup-supabase)
4. [Langkah 2: Setup Authentication](#langkah-2-setup-authentication)
5. [Langkah 3: Deploy Edge Functions](#langkah-3-deploy-edge-functions)
6. [Langkah 4: Deploy Frontend ke Vercel](#langkah-4-deploy-frontend-ke-vercel)
7. [Langkah 5: Konfigurasi Integrasi](#langkah-5-konfigurasi-integrasi)
8. [Langkah 6: Setup Custom Domain](#langkah-6-setup-custom-domain)
9. [Post-Deployment Checklist](#post-deployment-checklist)
10. [Troubleshooting](#troubleshooting)

---

## Arsitektur Deployment

```
┌─────────────────────────────────────────────────────────────┐
│                        USER BROWSER                          │
└────────────────────────────┬────────────────────────────────┘
                             │ HTTPS
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                    VERCEL (Frontend)                         │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  public/finance-pro.html (static)                   │    │
│  │  + Supabase JS Client                               │    │
│  └─────────────────────────────────────────────────────┘    │
└────────────────────────────┬────────────────────────────────┘
                             │
                             │ Supabase JS SDK
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                SUPABASE CLOUD (Backend)                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │  PostgreSQL  │  │  Auth (JWT)  │  │  Storage (files) │  │
│  │  + RLS       │  │              │  │                  │  │
│  └──────────────┘  └──────────────┘  └──────────────────┘  │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Edge Functions (Deno)                               │  │
│  │  ├── ai-assistant (Gemini/OpenAI proxy)             │  │
│  │  ├── post-journal (atomic double-entry)             │  │
│  │  ├── generate-doc-no (atomic sequence)              │  │
│  │  └── generate-financial-report                      │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                             │
                             │ HTTPS API call
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                AI PROVIDER (Gemini / OpenAI)                 │
└─────────────────────────────────────────────────────────────┘
```

---

## Prasyarat

- Akun [Supabase](https://supabase.com) (free tier OK untuk demo)
- Akun [Vercel](https://vercel.com) (free tier OK)
- Akun [GitHub](https://github.com) (untuk hosting repository)
- API key AI: [Google AI Studio](https://aistudio.google.com/app/apikey) (Gemini) atau [OpenAI](https://platform.openai.com/api-keys)
- Node.js 18+ dan npm terinstall
- Supabase CLI: `npm i -g supabase`
- Vercel CLI: `npm i -g vercel`

---

## Langkah 1: Setup Supabase

### 1.1 Buat Project Baru

1. Login ke [supabase.com](https://supabase.com)
2. Klik **New Project**
3. Isi:
   - **Name**: `finance-pro`
   - **Database Password**: (gunakan password kuat, simpan di password manager)
   - **Region**: pilih terdekat (Southeast Asia: Singapore untuk Indonesia)
   - **Plan**: Free tier OK
4. Tunggu ~2 menit sampai project ready

### 1.2 Catat Credentials

Buka **Settings → API**, catat:
- `Project URL`: `https://xxxxx.supabase.co`
- `anon public key`: `eyJhbGciOi...`
- `service_role key`: `eyJhbGciOi...` (JANGAN pernah taruh di frontend!)

### 1.3 Jalankan SQL Schema

1. Buka **SQL Editor** di sidebar Supabase Dashboard
2. Klik **New query**
3. Copy-paste isi file `supabase/schema.sql` → klik **Run**
4. Tunggu eksekusi selesai (sekitar 5-10 detik)
5. Ulangi untuk `supabase/rls-policies.sql` → klik **Run**
6. Ulangi untuk `supabase/seed.sql` → klik **Run**

### 1.4 Verifikasi

Jalankan query berikut untuk verifikasi:
```sql
-- Cek jumlah tabel
SELECT count(*) FROM information_schema.tables 
WHERE table_schema = 'public';

-- Expected: 38+ tabel

-- Cek RLS aktif
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' AND rowsecurity = true;

-- Cek sample data
SELECT count(*) FROM organizations; -- Expected: 1
SELECT count(*) FROM chart_of_accounts; -- Expected: 34
SELECT count(*) FROM departments; -- Expected: 9
```

---

## Langkah 2: Setup Authentication

### 2.1 Buat User di Supabase Auth

Untuk setiap user demo (7 user), lakukan:

1. Buka **Authentication → Users**
2. Klik **Add user → Create new user**
3. Isi:
   - **Email**: `admin@financepro.id`
   - **Password**: `admin123`
   - **Auto Confirm User**: ✅ (centang)
   - **User Metadata** (klik "Additional user data"):
     ```json
     {
       "name": "Admin Sistem",
       "role": "super_admin"
     }
     ```
4. Klik **Create user**

Ulangi untuk 6 user lainnya (lihat tabel di README.md).

### 2.2 Sinkronkan ke Profiles Table

Jalankan SQL berikut di SQL Editor:

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

-- Set department_id untuk kepala SMP
UPDATE public.profiles 
SET department_id = (SELECT id FROM public.departments WHERE code='SMP' LIMIT 1)
WHERE email = 'kepala.smp@financepro.id';

-- Verify
SELECT email, name, role FROM public.profiles;
```

### 2.3 Konfigurasi Auth Settings

Buka **Authentication → Providers**:
- Email: **Enabled** (sudah default)
- (Opsional) Google/GitHub OAuth untuk SSO

Buka **Authentication → URL Configuration**:
- **Site URL**: `https://your-app.vercel.app` (akan diisi setelah Step 4)
- **Redirect URLs**: tambahkan `https://your-app.vercel.app/**`

---

## Langkah 3: Deploy Edge Functions

### 3.1 Install Supabase CLI

```bash
npm i -g supabase
supabase --version  # harus >= 1.100.0
```

### 3.2 Login & Link Project

```bash
supabase login
# Ikuti prompt, buka URL di browser, authorize

# Dapatkan project ref dari URL Supabase Dashboard:
# https://supabase.com/dashboard/project/XXXXXXXX-XXXX-XXXX
#                                              ^^^^^^^^^^^^^^^^^^^^
#                                              ini project ref Anda

supabase link --project-ref YOUR_PROJECT_REF
```

### 3.3 Set Secrets

```bash
# Set environment variables untuk Edge Functions
supabase secrets set SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
supabase secrets set SUPABASE_ANON_KEY=your-anon-key-here
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here

# Set AI provider key (pilih salah satu)
supabase secrets set GEMINI_API_KEY=your-gemini-api-key
# atau
supabase secrets set OPENAI_API_KEY=your-openai-api-key

# Verify
supabase secrets list
```

### 3.4 Deploy Functions

```bash
# Masuk ke folder supabase
cd supabase/functions

# Deploy satu per satu
supabase functions deploy ai-assistant
supabase functions deploy post-journal
supabase functions deploy generate-doc-no
supabase functions deploy generate-financial-report

# Atau deploy semua sekaligus
supabase functions deploy
```

### 3.5 Verifikasi Functions

Test endpoint dengan curl:

```bash
# Test generate-doc-no (butuh JWT token dulu)
TOKEN="eyJhbGciOi...your-jwt-token"

curl -X POST \
  https://YOUR_PROJECT_REF.supabase.co/functions/v1/generate-doc-no \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"doc_type":"journal"}'

# Expected response:
# {"doc_no":"JV-2026-0002"}
```

---

## Langkah 4: Deploy Frontend ke Vercel

### 4.1 Persiapkan Repository

```bash
# Buat folder project
mkdir finance-pro
cd finance-pro

# Copy file dari download
cp /path/to/download/finance-pro.html ./public/
cp /path/to/download/.env.example .
cp -r /path/to/download/docs .
cp -r /path/to/download/supabase .

# Inisialisasi git
git init
git add .
git commit -m "Initial commit: Finance Pro v1.0.0"

# Buat repository di GitHub, lalu push
git remote add origin https://github.com/USERNAME/finance-pro.git
git push -u origin main
```

### 4.2 Deploy via Vercel Dashboard

1. Login ke [vercel.com](https://vercel.com)
2. Klik **Add New → Project**
3. Import repository GitHub Anda
4. Konfigurasi:
   - **Framework Preset**: Other
   - **Root Directory**: `./`
   - **Build Command**: (kosongkan - static site)
   - **Output Directory**: `./`
5. Set **Environment Variables**:
   - `NEXT_PUBLIC_SUPABASE_URL` = `https://YOUR_PROJECT.supabase.co`
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY` = `eyJhbGciOi...anon-key`
6. Klik **Deploy**
7. Tunggu ~30 detik, akses URL yang diberikan

### 4.3 Alternatif: Deploy via Vercel CLI

```bash
npm i -g vercel

# Di folder project
vercel

# Ikuti prompt:
# ? Set up and deploy "~/finance-pro"? Y
# ? Which scope? (pilih akun Anda)
# ? Link to existing project? N
# ? What's your project's name? finance-pro
# ? In which directory do you want to create your project? ./
# ? Want to modify these settings? N

# Set environment variables
vercel env add NEXT_PUBLIC_SUPABASE_URL
vercel env add NEXT_PUBLIC_SUPABASE_ANON_KEY

# Deploy ke production
vercel --prod
```

---

## Langkah 5: Konfigurasi Integrasi

Setelah Vercel memberi URL (misal `https://finance-pro.vercel.app`), lakukan:

### 5.1 Update Supabase Auth URLs

1. Buka Supabase Dashboard → **Authentication → URL Configuration**
2. Set **Site URL**: `https://finance-pro.vercel.app`
3. Tambahkan **Redirect URLs**:
   - `https://finance-pro.vercel.app/**`
   - `https://finance-pro.vercel.app/dashboard`

### 5.2 Integrasi Supabase Client ke HTML

Edit `public/finance-pro.html`, tambahkan Supabase JS SDK di `<head>`:

```html
<!-- Sebelum penutup </head> -->
<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
```

Lalu tambahkan kode berikut di awal script (sebelum `let DB = loadDB()`):

```javascript
// Supabase client (production mode)
const SUPABASE_URL = 'https://YOUR_PROJECT.supabase.co';
const SUPABASE_ANON_KEY = 'YOUR_ANON_KEY';
const sb = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Flag untuk switch antara demo (localStorage) dan production (Supabase)
const USE_SUPABASE = false; // Set true untuk production
```

Ganti fungsi `doLogin` untuk support Supabase Auth:

```javascript
async function doLogin(e) {
  e.preventDefault();
  const email = document.getElementById('loginEmail').value.trim().toLowerCase();
  const pwd = document.getElementById('loginPassword').value;
  
  if (USE_SUPABASE) {
    const { data, error } = await sb.auth.signInWithPassword({ email, password: pwd });
    if (error) {
      showToast('Login Gagal', error.message, 'error');
      return false;
    }
    // Load profile dari Supabase
    const { data: profile } = await sb.from('profiles')
      .select('*').eq('id', data.user.id).single();
    saveSession({ user: profile, remember });
    showApp();
  } else {
    // Demo mode (existing code)
    const user = DB.users.find(u => u.email.toLowerCase() === email && u.password === pwd);
    // ... existing logic
  }
  return false;
}
```

### 5.3 Update loadDB/saveDB (Production Mode)

```javascript
async function loadDB() {
  if (USE_SUPABASE) {
    // Production: fetch dari Supabase
    const [
      { data: orgs }, { data: depts }, { data: coa }, { data: cb },
      { data: budgets }, { data: incomes }, { data: expenses }, { data: transfers },
      { data: journals }, { data: rcv }, { data: pay }, { data: assets },
      { data: taxTypes }, { data: taxTx }, { data: audit }, { data: notif }
    ] = await Promise.all([
      sb.from('organizations').select('*'),
      sb.from('departments').select('*'),
      sb.from('chart_of_accounts').select('*'),
      sb.from('cash_bank_accounts').select('*'),
      sb.from('budget_plans').select('*'),
      sb.from('income_transactions').select('*'),
      sb.from('expense_requests').select('*'),
      sb.from('fund_transfers').select('*'),
      sb.from('journal_entries').select('*, journal_details(*)'),
      sb.from('receivables').select('*'),
      sb.from('payables').select('*'),
      sb.from('fixed_assets').select('*'),
      sb.from('tax_types').select('*'),
      sb.from('tax_transactions').select('*'),
      sb.from('audit_logs').select('*').order('created_at', { ascending: false }).limit(100),
      sb.from('notifications').select('*')
    ]);
    return {
      organizations: orgs || [], departments: depts || [], chart_of_accounts: coa || [],
      cash_bank_accounts: cb || [], budget_plans: budgets || [], income_transactions: incomes || [],
      expense_requests: expenses || [], transfers: transfers || [], journal_entries: journals || [],
      receivables: rcv || [], payables: pay || [], fixed_assets: assets || [],
      tax_types: taxTypes || [], tax_transactions: taxTx || [],
      audit_logs: audit || [], notifications: notif || [], doc_sequences: {}
    };
  } else {
    // Demo mode (existing code)
    try {
      const raw = localStorage.getItem(DB_KEY);
      if (raw) return JSON.parse(raw);
    } catch(e) {}
    const fresh = defaultDB();
    seedBudgetsAndTransactions(fresh);
    localStorage.setItem(DB_KEY, JSON.stringify(fresh));
    return fresh;
  }
}
```

### 5.4 Commit & Redeploy

```bash
git add .
git commit -m "feat: integrate Supabase backend"
git push

# Vercel akan auto-deploy
```

---

## Langkah 6: Setup Custom Domain (Opsional)

### 6.1 Di Vercel

1. Buka project di Vercel Dashboard
2. **Settings → Domains**
3. Tambahkan domain Anda, misal `finance.yayasan-anda.or.id`
4. Ikuti instruksi DNS (tambah CNAME record di registrar)

### 6.2 Update Supabase URLs

- Update **Site URL** di Supabase Auth
- Update CORS di Edge Functions (sudah `*` by default)

### 6.3 Setup SSL

Vercel otomatis provide SSL via Let's Encrypt. Tidak perlu konfigurasi tambahan.

---

## Post-Deployment Checklist

Setelah deploy, verifikasi:

- [ ] Halaman login dapat diakses di production URL
- [ ] Login dengan akun demo berhasil
- [ ] Dashboard load dengan data dari Supabase
- [ ] CRUD modul master data berfungsi
- [ ] Pencatatan pemasukan/pengeluaran tersimpan ke Supabase
- [ ] Jurnal otomatis terbentuk saat transaksi diposting
- [ ] Laporan keuangan menampilkan data benar
- [ ] Audit trail mencatat aktivitas
- [ ] RLS policies aktif (test dengan user berbeda)
- [ ] AI Assistant berfungsi (jika API key diset)
- [ ] Export CSV/PDF berfungsi
- [ ] Mobile responsive OK
- [ ] SSL/HTTPS aktif (lock icon di browser)
- [ ] Performance < 3 detik load time

---

## Troubleshooting

### Masalah: Login gagal di production

**Kemungkinan penyebab:**
1. Site URL di Supabase Auth belum diupdate → update ke URL Vercel
2. User belum di-create di auth.users → buat manual di Supabase Dashboard
3. Profile belum di-sync ke `profiles` table → jalankan SQL sync

**Solusi:**
```sql
-- Cek apakah user ada di auth.users
SELECT id, email FROM auth.users;

-- Cek apakah profile ada
SELECT id, email, role FROM public.profiles;

-- Sync jika belum
INSERT INTO public.profiles (id, organization_id, email, name, role, active)
SELECT u.id, 'a0000001-0000-0000-0000-000000000001'::UUID, u.email,
       COALESCE(u.raw_user_meta_data->>'name','User'),
       COALESCE(u.raw_user_meta_data->>'role','pengguna_unit'), TRUE
FROM auth.users u
WHERE NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = u.id);
```

### Masalah: RLS blocking semua query

**Kemungkinan:** User tidak punya organization_id di profile.

**Solusi:**
```sql
UPDATE public.profiles 
SET organization_id = 'a0000001-0000-0000-0000-000000000001'::UUID
WHERE organization_id IS NULL;
```

### Masalah: Edge Function return 401

**Kemungkinan:** JWT token tidak terkirim atau expired.

**Solusi:** Pastikan frontend mengirim Authorization header:
```javascript
const { data: { session } } = await sb.auth.getSession();
const response = await fetch('/functions/v1/ai-assistant', {
  headers: {
    'Authorization': `Bearer ${session.access_token}`,
    'Content-Type': 'application/json'
  },
  method: 'POST',
  body: JSON.stringify({ question: '...' })
});
```

### Masalah: AI Assistant return "Mode demo aktif"

**Kemungkinan:** `GEMINI_API_KEY` / `OPENAI_API_KEY` belum diset.

**Solusi:**
```bash
supabase secrets set GEMINI_API_KEY=your-actual-key
supabase functions deploy ai-assistant
```

### Masalah: Build fail di Vercel

**Solusi:** Karena ini static HTML, build tidak seharusnya fail. Pastikan:
- Output Directory: `./`
- Build Command: kosong
- Tidak ada file `.next` atau `node_modules` yang harus dibuild

---

## Backup & Maintenance

### Backup Database

```bash
# Manual backup via pg_dump
supabase db dump --data-only > backup-$(date +%Y%m%d).sql

# Atau via Supabase Dashboard → Database → Backups
# Free tier: backup harian otomatis, retention 7 hari
# Pro tier: Point-in-time recovery (PITR) tersedia
```

### Restore

```bash
supabase db restore < backup-2026-01-15.sql
```

### Monitor Usage

- Supabase Dashboard → Reports (API calls, database size, auth users)
- Vercel Dashboard → Analytics (traffic, performance)
- Setup alerts untuk usage mendekati limit

---

## Scaling Notes

| Komponen | Free Tier Limit | Recommended Upgrade |
|----------|----------------|---------------------|
| Supabase Database | 500MB | Pro $25/bln (8GB) |
| Supabase Auth | 50,000 MAU | Pro (100,000 MAU) |
| Supabase Storage | 1GB | Pro (100GB) |
| Edge Functions | 500K invocations/bln | Pro (2M) |
| Vercel | 100GB bandwidth | Pro $20/bln (1TB) |
| Gemini API | Free tier (15 RPM) | Pay-as-you-go |
| OpenAI API | Pay-as-you-go | (no free tier) |

**Rekomendasi:** Untuk organisasi dengan < 100 user, free tier Supabase + Vercel sudah cukup. Untuk production skala besar, upgrade ke Pro.

---

**Selamat! Aplikasi FINANCE PRO sudah siap produksi.**
