# Contributing to FINANCE PRO

Terima kasih atas minat Anda untuk berkontribusi pada FINANCE PRO! 

## Cara Berkontribusi

### 1. Fork & Clone Repository

```bash
git clone https://github.com/YOUR-USERNAME/finance-pro.git
cd finance-pro
```

### 2. Buat Branch Baru

```bash
git checkout -b feature/nama-fitur
# atau
git checkout -b fix/nama-bug
```

### 3. Lakukan Perubahan

- Ikuti konvensi kode yang ada
- Test perubahan Anda secara lokal
- Pastikan tidak ada file `.env` atau secret yang ter-commit

### 4. Commit dengan Format Conventional

```bash
git commit -m "feat: tambah fitur export PDF untuk laporan neraca"
git commit -m "fix: perbaikan validasi debit=kredit di jurnal manual"
git commit -m "docs: update panduan deployment"
```

Format: `<type>: <deskripsi>`

Tipe:
- `feat`: fitur baru
- `fix`: bug fix
- `docs`: dokumentasi
- `style`: format/tampilan
- `refactor`: refactoring kode
- `test`: tambah test
- `chore`: maintenance

### 5. Push & Buat Pull Request

```bash
git push origin feature/nama-fitur
```

Buka Pull Request di GitHub dengan deskripsi yang jelas.

## Standar Kode

### JavaScript
- Gunakan ES6+ syntax
- 2 spasi indentasi
- Naming convention: camelCase untuk variabel, PascalCase untuk class
- Semua fungsi publik harus ada JSDoc comment

### SQL
- Nama tabel: plural snake_case (cth: `budget_plans`)
- Nama kolom: snake_case (cth: `created_at`)
- UUID primary key
- Selalu sertakan `organization_id` untuk multi-tenant
- Tambahkan index untuk kolom yang sering di-query

### TypeScript (Edge Functions)
- Strict mode
- Validasi input dengan interface
- Tidak menaruh secret di kode
- Gunakan CORS preflight handler

## Testing

Sebelum submit PR, pastikan:
- [ ] Aplikasi masih bisa login dengan akun demo
- [ ] Dashboard render tanpa error
- [ ] Modul yang diubah berfungsi
- [ ] Tidak ada console error di browser
- [ ] Tidak ada data sensitif yang ter-commit

## Reporting Issues

Saat melaporkan bug, sertakan:
- Langkah reproduksi
- Expected vs actual behavior
- Browser & OS
- Screenshot (jika ada)

## Code of Conduct

- Bersikap profesional dan ramah
- Hormati perbedaan pendapat
- Fokus pada masalah teknis, bukan personal
- Terima kritik konstruktif

---

Terima kasih telah membuat FINANCE PRO lebih baik!
