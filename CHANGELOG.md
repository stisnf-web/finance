# Changelog

Semua perubahan penting pada proyek ini akan didokumentasikan di file ini.

Format berdasarkan [Keep a Changelog](https://keepachangelog.com/id-ID/1.0.0/),
dan proyek ini mengikuti [Semantic Versioning](https://semver.org/lang/id/).

## [1.0.0] - 2026-11-17

### Added
- **Dashboard Keuangan**: 8 KPI cards + 5 grafik interaktif (Chart.js)
- **Master Data**: Organisasi (multi-tenant), Struktur Departemen bertingkat, Chart of Accounts 34 akun, Kas & Bank
- **Anggaran**: Penyusunan (Volume × Harga), Workflow approval (Draft→Submitted→Approved), Monitoring realisasi dengan indikator status (Aman/Perlu Diperhatikan/Mendekati/Melebihi)
- **Transaksi**: Pemasukan (auto-jurnal), Pengeluaran (4-step workflow), Transfer antar rekening (tidak double-counting)
- **Accounting Engine**: Jurnal double-entry dengan validasi Debit=Kredit, Buku Besar, Neraca Saldo, Atomic posting via PostgreSQL function
- **Laporan Keuangan**: Neraca, Laba Rugi, Arus Kas, Perubahan Ekuitas, Neraca Saldo, Buku Besar, Jurnal Umum, Anggaran vs Realisasi, Piutang, Utang, Aset, Pajak
- **Advanced Finance**: Piutang/Utang dengan umur, Aset Tetap (penyusutan straight-line), Rekonsiliasi Bank (import CSV), Perpajakan (PPh 21/23/PPN/Final)
- **Approval Workflow**: Berjenjang configurable per nominal, dengan visualisasi 4-step
- **Audit Trail**: Log immutable (trigger prevent UPDATE/DELETE)
- **AI Financial Assistant**: Chat dengan AI (Gemini/OpenAI), analisis realisasi anggaran, deviasi, posisi kas, narasi laporan, rekomendasi efisiensi
- **Settings**: 12 konfigurasi modul, manajemen user & role, backup/restore data
- **RBAC**: 11 role (super_admin, ketua, direktur, manager_finance, staf_akuntansi, bendahara, kepala_departemen, kepala_unit, auditor, pengguna_unit, admin_org)
- **Multi-tenant**: RLS policies untuk isolasi data per organisasi
- **Export**: CSV semua modul, Print/PDF laporan utama
- **Mobile Responsive**: Sidebar collapse, KPI grid adaptif

### Database
- 41 tabel PostgreSQL dengan foreign keys, check constraints, indexes
- 7 PL/pgSQL functions (post_journal, next_doc_number, refresh_account_balances, log_audit, touch_updated_at, prevent_audit_modify, current_user_org/role)
- 12 triggers (auto updated_at, audit_logs append-only)
- 43 RLS policies untuk multi-tenant + RBAC
- 1 materialized view (mv_account_balances) untuk performa laporan
- Seed data: 1 organization, 9 departemen, 34 COA, 4 rekening, 7 anggaran, 8 pemasukan, 11 pengeluaran, 3 transfer, 19+ jurnal, 3 piutang, 3 utang, 3 aset, 3 pajak

### Edge Functions
- `ai-assistant`: Proxy AI dengan RBAC-scoped context, fallback rule-based, logging
- `post-journal`: Atomic journal posting dengan validasi double-entry & periode
- `generate-doc-no`: Atomic document number generator (anti-duplikasi concurrent)
- `generate-financial-report`: Generator 6 jenis laporan keuangan dari materialized view

### Documentation
- README.md (407 baris): Overview, fitur, quick start, deployment summary
- docs/DEPLOYMENT.md (613 baris): Panduan Vercel + Supabase 6 langkah, troubleshooting
- docs/TESTING.md (297 baris): 80+ skenario pengujian fungsional/akuntansi/keamanan
- docs/USER_GUIDE.md (451 baris): Panduan end-user semua modul, FAQ
- CONTRIBUTING.md: Panduan kontribusi
- CHANGELOG.md: Riwayat perubahan
- LICENSE: MIT

### Security
- Supabase Authentication (JWT)
- Row Level Security (RLS) di semua tabel tenant
- Audit trail immutable (trigger prevent UPDATE/DELETE)
- Input validation via CHECK constraints
- XSS protection via Bootstrap + proper escaping
- SQL injection protection via parameterized queries (Supabase client)
- API keys di Edge Function secrets (BUKAN di frontend)
- Segregation of Duties via RBAC

### Tech Stack
- **Frontend**: HTML5, CSS3, JavaScript ES6+, Bootstrap 5, Font Awesome 6, Chart.js 4
- **Backend**: Supabase PostgreSQL 15, Supabase Auth, Supabase Storage, Supabase Edge Functions (Deno)
- **AI**: Google Gemini API (primary), OpenAI API (fallback)
- **Deployment**: Vercel (frontend), Supabase Cloud (backend)

---

## Naming Convention

- `feat:` fitur baru
- `fix:` bug fix
- `docs:` perubahan dokumentasi
- `style:` perubahan format/tampilan
- `refactor:` refactoring kode
- `test:` tambah atau perbaiki test
- `chore:` maintenance, dependencies, dll

## Version History

- **v1.0.0** (2026-11-17): Initial production release
