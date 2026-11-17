-- =====================================================================
-- FINANCE PRO - Seed Data
-- Initial demo data for testing the application
-- Run AFTER schema.sql and rls-policies.sql
-- =====================================================================

-- 1. Demo organization
INSERT INTO public.organizations (id, name, slug, type, address, phone, email, npwp, head, established, fiscal_year, currency, bookkeeping_method, active)
VALUES (
  'a0000001-0000-0000-0000-000000000001',
  'Yayasan Pendidikan Nur Hidayah',
  'yp-nur-hidayah',
  'yayasan',
  'Jl. Merdeka No. 45, Kota Bandung, Jawa Barat',
  '022-1234567',
  'info@nurhidayah.or.id',
  '01.234.567.8-901.000',
  'H. Ahmad Fauzi, S.E., M.M.',
  '2010-01-01',
  2026,
  'IDR',
  'double_entry',
  TRUE
);

-- 2. Departments (organizational structure)
INSERT INTO public.departments (organization_id, code, name, type, parent_id, level, head, active) VALUES
  ('a0000001-0000-0000-0000-000000000001', 'DIR-PEND', 'Direktorat Pendidikan', 'directorate', NULL, 1, 'Dr. Siti Aminah, M.Pd.', TRUE),
  ('a0000001-0000-0000-0000-000000000001', 'SMP', 'Departemen SMP', 'department', (SELECT id FROM public.departments WHERE code='DIR-PEND'), 2, 'Drs. Bambang S., M.Pd.', TRUE),
  ('a0000001-0000-0000-0000-000000000001', 'SMA', 'Departemen SMA', 'department', (SELECT id FROM public.departments WHERE code='DIR-PEND'), 2, 'Hj. Ratna D., S.Pd.', TRUE),
  ('a0000001-0000-0000-0000-000000000001', 'PAI', 'Departemen Pendidikan Al-Qur''an', 'department', (SELECT id FROM public.departments WHERE code='DIR-PEND'), 2, 'Ust. Yusuf M., S.Pd.I', TRUE),
  ('a0000001-0000-0000-0000-000000000001', 'DIR-PEL', 'Direktorat Pelayanan', 'directorate', NULL, 1, 'H. Abdullah R., S.Sos.', TRUE),
  ('a0000001-0000-0000-0000-000000000001', 'HRD', 'HRD', 'department', (SELECT id FROM public.departments WHERE code='DIR-PEL'), 2, 'Siti Rohmah, S.Psi.', TRUE),
  ('a0000001-0000-0000-0000-000000000001', 'FIN', 'Keuangan', 'department', (SELECT id FROM public.departments WHERE code='DIR-PEL'), 2, 'Andi Wijaya, S.E.', TRUE),
  ('a0000001-0000-0000-0000-000000000001', 'HUM', 'Humas', 'department', (SELECT id FROM public.departments WHERE code='DIR-PEL'), 2, 'Maya P., S.Kom.', TRUE),
  ('a0000001-0000-0000-0000-000000000001', 'PURT', 'PURT (Pemeliharaan Umum)', 'department', (SELECT id FROM public.departments WHERE code='DIR-PEL'), 2, 'Joko S., S.T.', TRUE);

-- 3. Fiscal year & periods
INSERT INTO public.fiscal_years (organization_id, year, start_date, end_date, status) VALUES
  ('a0000001-0000-0000-0000-000000000001', 2026, '2026-01-01', '2026-12-31', 'open');

INSERT INTO public.accounting_periods (organization_id, fiscal_year_id, period, start_date, end_date, status)
SELECT
  'a0000001-0000-0000-0000-000000000001',
  fy.id,
  TO_CHAR(d::DATE, 'YYYY-MM'),
  d::DATE,
  (d + INTERVAL '1 month - 1 day')::DATE,
  'open'
FROM public.fiscal_years fy,
LATERAL generate_series('2026-01-01'::DATE, '2026-12-01'::DATE, INTERVAL '1 month') AS d
WHERE fy.organization_id = 'a0000001-0000-0000-0000-000000000001' AND fy.year = 2026;

-- 4. Chart of Accounts
INSERT INTO public.chart_of_accounts (organization_id, code, name, type, subtype, parent_id, level, is_group, active) VALUES
  ('a0000001-0000-0000-0000-000000000001', '1100', 'Kas dan Bank', 'asset', 'kas_bank', NULL, 1, TRUE, TRUE),
  ('a0000001-0000-0000-0000-000000000001', '1110', 'Kas Besar', 'asset', 'kas', NULL, 2, FALSE, TRUE),
  ('a0000001-0000-0000-0000-000000000001', '1120', 'Kas Kecil', 'asset', 'kas', NULL, 2, FALSE, TRUE),
  ('a0000001-0000-0000-0000-000000000001', '1130', 'Bank BCA', 'asset', 'bank', NULL, 2, FALSE, TRUE),
  ('a0000001-0000-0000-0000-000000000001', '1140', 'Bank Mandiri', 'asset', 'bank', NULL, 2, FALSE, TRUE),
  ('a0000001-0000-0000-0000-000000000001', '1200', 'Piutang', 'asset', 'piutang', NULL, 1, TRUE, TRUE),
  ('a0000001-0000-0000-0000-000000000001', '1210', 'Piutang Siswa', 'asset', 'piutang', NULL, 2, FALSE, TRUE),
  ('a0000001-0000-0000-0000-000000000001', '1300', 'Persediaan', 'asset', 'persediaan', NULL, 1, TRUE, TRUE),
  ('a0000001-0000-0000-0000-000000000001', '1400', 'Aset Tetap', 'asset', 'aset_tetap', NULL, 1, TRUE, TRUE),
  ('a0000001-0000-0000-0000-000000000001', '1410', 'Peralatan', 'asset', 'aset_tetap', NULL, 2, FALSE, TRUE),
  ('a0000001-0000-0000-0000-000000000001', '1420', 'Bangunan', 'asset', 'aset_tetap', NULL, 2, FALSE, TRUE),
  ('a0000001-0000-0000-0000-000000000001', '1430', 'Kendaraan', 'asset', 'aset_tetap', NULL, 2, FALSE, TRUE),
  ('a0000001-0000-0000-0000-000000000001', '2100', 'Utang Usaha', 'liabilitas', 'utang', NULL, 1, TRUE, TRUE),
  ('a0000001-0000-0000-0000-000000000001', '2200', 'Utang Pajak', 'liabilitas', 'utang', NULL, 1, TRUE, TRUE),
  ('a0000001-0000-0000-0000-000000000001', '2210', 'Utang PPh 21', 'liabilitas', 'utang', NULL, 2, FALSE, TRUE),
  ('a0000001-0000-0000-0000-000000000001', '2220', 'Utang PPh 23', 'liabilitas', 'utang', NULL, 2, FALSE, TRUE),
  ('a0000001-0000-0000-0000-000000000001', '2300', 'Utang Lainnya', 'liabilitas', 'utang', NULL, 1, TRUE, TRUE),
  ('a0000001-0000-0000-0000-000000000001', '3100', 'Saldo Dana Yayasan', 'ekuitas', 'aset_neto', NULL, 1, FALSE, TRUE),
  ('a0000001-0000-0000-0000-000000000001', '3200', 'Saldo Awal', 'ekuitas', 'aset_neto', NULL, 1, FALSE, TRUE),
  ('a0000001-0000-0000-0000-000000000001', '3300', 'Perubahan Aset Neto', 'ekuitas', 'aset_neto', NULL, 1, FALSE, TRUE),
  ('a0000001-0000-0000-0000-000000000001', '4100', 'Pendapatan Operasional', 'pendapatan', 'operasional', NULL, 1, TRUE, TRUE),
  ('a0000001-0000-0000-0000-000000000001', '4110', 'SPP & Uang Pangkal', 'pendapatan', 'pendidikan', NULL, 2, FALSE, TRUE),
  ('a0000001-0000-0000-0000-000000000001', '4200', 'Pendapatan Usaha', 'pendapatan', 'usaha', NULL, 1, TRUE, TRUE),
  ('a0000001-0000-0000-0000-000000000001', '4210', 'Pendapatan Kantin', 'pendapatan', 'usaha', NULL, 2, FALSE, TRUE),
  ('a0000001-0000-0000-0000-000000000001', '4300', 'Donasi & Hibah', 'pendapatan', 'donasi', NULL, 1, TRUE, TRUE),
  ('a0000001-0000-0000-0000-000000000001', '4400', 'Pendapatan Lainnya', 'pendapatan', 'lain', NULL, 1, TRUE, TRUE),
  ('a0000001-0000-0000-0000-000000000001', '5100', 'Beban Gaji & Remunerasi', 'beban', 'gaji', NULL, 1, FALSE, TRUE),
  ('a0000001-0000-0000-0000-000000000001', '5200', 'Beban Operasional', 'beban', 'operasional', NULL, 1, TRUE, TRUE),
  ('a0000001-0000-0000-0000-000000000001', '5210', 'Beban Listrik & Air', 'beban', 'operasional', NULL, 2, FALSE, TRUE),
  ('a0000001-0000-0000-0000-000000000001', '5220', 'Beban Pemeliharaan', 'beban', 'pemeliharaan', NULL, 2, FALSE, TRUE),
  ('a0000001-0000-0000-0000-000000000001', '5300', 'Beban Pendidikan', 'beban', 'pendidikan', NULL, 1, FALSE, TRUE),
  ('a0000001-0000-0000-0000-000000000001', '5400', 'Beban Administrasi', 'beban', 'administrasi', NULL, 1, FALSE, TRUE),
  ('a0000001-0000-0000-0000-000000000001', '5500', 'Beban Konsumsi & Kegiatan', 'beban', 'konsumsi', NULL, 1, FALSE, TRUE),
  ('a0000001-0000-0000-0000-000000000001', '5600', 'Beban Perjalanan Dinas', 'beban', 'perjalanan', NULL, 1, FALSE, TRUE);

-- 5. Cash & Bank accounts
INSERT INTO public.cash_bank_accounts (organization_id, name, type, account_code, bank_name, account_number, holder, opening_balance, balance, active) VALUES
  ('a0000001-0000-0000-0000-000000000001', 'Kas Besar', 'kas', '1110', NULL, NULL, 'Bendahara Utama', 25000000, 25000000, TRUE),
  ('a0000001-0000-0000-0000-000000000001', 'Kas Kecil', 'kas', '1120', NULL, NULL, 'Kasir PURT', 5000000, 5000000, TRUE),
  ('a0000001-0000-0000-0000-000000000001', 'Bank BCA - 1234567890', 'bank', '1130', 'BCA', '1234567890', 'Yayasan Nur Hidayah', 150000000, 150000000, TRUE),
  ('a0000001-0000-0000-0000-000000000001', 'Bank Mandiri - 0987654321', 'bank', '1140', 'Mandiri', '0987654321', 'Yayasan Nur Hidayah', 80000000, 80000000, TRUE);

-- 6. Budget plans
INSERT INTO public.budget_plans (organization_id, budget_no, year, department_id, account_code, description, volume, unit, unit_price, total, approved_amount, realization, pic, status) VALUES
  ('a0000001-0000-0000-0000-000000000001', 'BUD-2026-0001', 2026, (SELECT id FROM public.departments WHERE code='SMP'),  '5xxx', 'Anggaran operasional SMP tahun 2026', 1, 'Paket', 850000000, 850000000, 850000000, 425000000, 'Drs. Bambang S., M.Pd.', 'approved'),
  ('a0000001-0000-0000-0000-000000000001', 'BUD-2026-0002', 2026, (SELECT id FROM public.departments WHERE code='SMA'),  '5xxx', 'Anggaran operasional SMA tahun 2026', 1, 'Paket', 950000000, 950000000, 950000000, 570000000, 'Hj. Ratna D., S.Pd.', 'approved'),
  ('a0000001-0000-0000-0000-000000000001', 'BUD-2026-0003', 2026, (SELECT id FROM public.departments WHERE code='PAI'),  '5xxx', 'Anggaran operasional PAI tahun 2026', 1, 'Paket', 420000000, 420000000, 420000000, 210000000, 'Ust. Yusuf M., S.Pd.I', 'approved'),
  ('a0000001-0000-0000-0000-000000000001', 'BUD-2026-0004', 2026, (SELECT id FROM public.departments WHERE code='HRD'),  '5xxx', 'Anggaran operasional HRD tahun 2026', 1, 'Paket', 580000000, 580000000, 580000000, 522000000, 'Siti Rohmah, S.Psi.', 'approved'),
  ('a0000001-0000-0000-0000-000000000001', 'BUD-2026-0005', 2026, (SELECT id FROM public.departments WHERE code='FIN'),  '5xxx', 'Anggaran operasional Keuangan tahun 2026', 1, 'Paket', 280000000, 280000000, 280000000, 140000000, 'Andi Wijaya, S.E.', 'approved'),
  ('a0000001-0000-0000-0000-000000000001', 'BUD-2026-0006', 2026, (SELECT id FROM public.departments WHERE code='HUM'),  '5xxx', 'Anggaran operasional Humas tahun 2026', 1, 'Paket', 180000000, 180000000, 180000000, 72000000, 'Maya P., S.Kom.', 'approved'),
  ('a0000001-0000-0000-0000-000000000001', 'BUD-2026-0007', 2026, (SELECT id FROM public.departments WHERE code='PURT'), '5xxx', 'Anggaran operasional PURT tahun 2026', 1, 'Paket', 350000000, 350000000, 350000000, 175000000, 'Joko S., S.T.', 'approved');

-- 7. Opening balance journal
INSERT INTO public.journal_entries (organization_id, journal_no, date, type, ref_type, ref_no, description, period, status, total_debit, total_credit)
VALUES ('a0000001-0000-0000-0000-000000000001', 'JV-2026-0001', '2026-01-01', 'jurnal_pembuka', 'opening', 'OPN-2026', 'Saldo awal tahun buku 2026', '2026-01', 'posted', 260000000, 260000000);

INSERT INTO public.journal_details (journal_id, account_code, description, debit, credit) VALUES
  ((SELECT id FROM public.journal_entries WHERE journal_no='JV-2026-0001'), '1110', 'Saldo awal Kas Besar', 25000000, 0),
  ((SELECT id FROM public.journal_entries WHERE journal_no='JV-2026-0001'), '1120', 'Saldo awal Kas Kecil', 5000000, 0),
  ((SELECT id FROM public.journal_entries WHERE journal_no='JV-2026-0001'), '1130', 'Saldo awal Bank BCA', 150000000, 0),
  ((SELECT id FROM public.journal_entries WHERE journal_no='JV-2026-0001'), '1140', 'Saldo awal Bank Mandiri', 80000000, 0),
  ((SELECT id FROM public.journal_entries WHERE journal_no='JV-2026-0001'), '3200', 'Saldo awal dana yayasan', 0, 260000000);

-- 8. Fixed assets
INSERT INTO public.fixed_assets (organization_id, code, name, category, purchase_date, acquisition_value, accumulated_dep, book_value, location, responsible, useful_life, depreciation_method, status) VALUES
  ('a0000001-0000-0000-0000-000000000001', 'AST-001', 'Komputer PC Lab 1', 'peralatan', '2024-07-01', 12000000, 4800000, 7200000, 'Lab Komputer', 'Pak Hendra', 5, 'straight_line', 'active'),
  ('a0000001-0000-0000-0000-000000000001', 'AST-002', 'Mobil Operasional', 'kendaraan', '2023-01-15', 250000000, 109375000, 140625000, 'Garasi', 'Pak Joko', 8, 'straight_line', 'active'),
  ('a0000001-0000-0000-0000-000000000001', 'AST-003', 'Gedung Sekolah SMA', 'bangunan', '2010-09-01', 1500000000, 550000000, 950000000, 'SMA', 'Yayasan', 30, 'straight_line', 'active');

-- 9. Receivables
INSERT INTO public.receivables (organization_id, customer_name, invoice_no, invoice_date, due_date, amount, paid, status) VALUES
  ('a0000001-0000-0000-0000-000000000001', 'Siswa Kelas 7 - Ahmad Z.', 'INV-2026-0001', '2026-01-15', '2026-02-15', 3500000, 1500000, 'partial'),
  ('a0000001-0000-0000-0000-000000000001', 'Siswa Kelas 8 - Siti Kh.', 'INV-2026-0002', '2026-02-01', '2026-03-01', 2800000, 0, 'unpaid'),
  ('a0000001-0000-0000-0000-000000000001', 'PT Edukasi Jaya (Hibah)', 'INV-2026-0003', '2026-01-20', '2026-03-20', 50000000, 50000000, 'paid');

-- 10. Payables
INSERT INTO public.payables (organization_id, vendor_name, invoice_no, invoice_date, due_date, amount, paid, status) VALUES
  ('a0000001-0000-0000-0000-000000000001', 'CV Sumber Rezeki (ATK)', 'BILL-V-001', '2026-02-05', '2026-03-05', 8500000, 0, 'unpaid'),
  ('a0000001-0000-0000-0000-000000000001', 'PT Listrik Mandiri', 'PLN-2026-02', '2026-02-10', '2026-02-25', 4250000, 4250000, 'paid'),
  ('a0000001-0000-0000-0000-000000000001', 'Toko Mebel Jati', 'INV-MB-009', '2026-02-15', '2026-03-15', 18500000, 5000000, 'partial');

-- 11. Tax types & transactions
INSERT INTO public.tax_types (organization_id, name, rate, description, active) VALUES
  ('a0000001-0000-0000-0000-000000000001', 'PPh 21', 5.00, 'Pajak Penghasilan Pasal 21 - Gaji', TRUE),
  ('a0000001-0000-0000-0000-000000000001', 'PPh 23', 2.00, 'Pajak Penghasilan Pasal 23', TRUE),
  ('a0000001-0000-0000-0000-000000000001', 'PPN', 11.00, 'Pajak Pertambahan Nilai', TRUE),
  ('a0000001-0000-0000-0000-000000000001', 'PPh Final', 0.50, 'Pajak Penghasilan Final UMKM', TRUE);

INSERT INTO public.tax_transactions (organization_id, tax_type, period, base_amount, tax_amount, tax_out, tax_in, status) VALUES
  ('a0000001-0000-0000-0000-000000000001', 'PPh 21', '2026-02', 185000000, 9250000, NULL, NULL, 'payable'),
  ('a0000001-0000-0000-0000-000000000001', 'PPh 23', '2026-02', 45000000, 900000, NULL, NULL, 'payable'),
  ('a0000001-0000-0000-0000-000000000001', 'PPN',   '2026-02', 125000000, 8250000, 13750000, 5500000, 'payable');

-- 12. Notifications
INSERT INTO public.notifications (organization_id, title, message, icon, page, read) VALUES
  ('a0000001-0000-0000-0000-000000000001', '3 Pengajuan menunggu persetujuan', 'Terdapat 3 pengajuan yang menunggu approval Anda', 'fa-bell', 'approvals', FALSE),
  ('a0000001-0000-0000-0000-000000000001', 'Anggaran HRD mencapai 85% realisasi', 'Anggaran HRD mendekati batas, mohon periksa', 'fa-exclamation-triangle', 'budget-realization', FALSE),
  ('a0000001-0000-0000-0000-000000000001', 'Jurnal otomatis JV-2026-0124 berhasil diposting', 'Posting jurnal untuk pengeluaran terbaru', 'fa-check', 'journal', TRUE);

-- 13. Demo audit logs
INSERT INTO public.audit_logs (organization_id, user_name, action, description, ref_no, created_at) VALUES
  ('a0000001-0000-0000-0000-000000000001', 'Admin Sistem', 'Login', 'Login ke sistem', '-', '2026-03-15T08:00:00'),
  ('a0000001-0000-0000-0000-000000000001', 'Andi Wijaya', 'Approval Anggaran', 'Menyetujui 7 anggaran tahun 2026', 'BUD-2026-0001 s/d 0007', '2025-12-20T10:00:00'),
  ('a0000001-0000-0000-0000-000000000001', 'Dewi Susanti', 'Pencatatan Pemasukan', 'Pencatatan penerimaan SPP', 'INC-2026-0004', '2026-02-05T08:30:00'),
  ('a0000001-0000-0000-0000-000000000001', 'Andi Wijaya', 'Approval Pengeluaran', 'Approval penggajian Februari', 'EXP-2026-0004', '2026-02-08T14:00:00'),
  ('a0000001-0000-0000-0000-000000000001', 'Rina Marlina', 'Posting Jurnal', 'Posting jurnal otomatis', 'JV-2026-0011', '2026-02-08T14:01:00');

-- =====================================================================
-- NOTE: Untuk membuat user login, gunakan Supabase Dashboard Auth:
--   - admin@financepro.id / admin123       → role: super_admin
--   - ketua@financepro.id / ketua123        → role: ketua
--   - finance@financepro.id / finance123   → role: manager_finance
--   - akuntan@financepro.id / akuntan123   → role: staf_akuntansi
--   - bendahara@financepro.id / bendahara123 → role: bendahara
--   - kepala.smp@financepro.id / kepala123 → role: kepala_departemen
--   - auditor@financepro.id / auditor123  → role: auditor
-- Setelah create user di auth.users, jalankan:
--   INSERT INTO public.profiles (id, organization_id, email, name, role, department_id, active)
--   SELECT
--     u.id,
--     'a0000001-0000-0000-0000-000000000001'::UUID,
--     u.email,
--     COALESCE(u.raw_user_meta_data->>'name', split_part(u.email,'@',1)),
--     COALESCE(u.raw_user_meta_data->>'role', 'pengguna_unit'),
--     NULL, TRUE
--   FROM auth.users u
--   WHERE NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = u.id);
-- =====================================================================

-- 14. Approval workflow sample
INSERT INTO public.approval_workflows (organization_id, name, transaction_type, min_amount, max_amount, active) VALUES
  ('a0000001-0000-0000-0000-000000000001', 'Workflow Pengeluaran < 10jt', 'expense', 0, 10000000, TRUE),
  ('a0000001-0000-0000-0000-000000000001', 'Workflow Pengeluaran 10jt-100jt', 'expense', 10000000, 100000000, TRUE),
  ('a0000001-0000-0000-0000-000000000001', 'Workflow Pengeluaran > 100jt', 'expense', 100000000, 99999999999, TRUE),
  ('a0000001-0000-0000-0000-000000000001', 'Workflow Anggaran', 'budget', 0, 99999999999, TRUE);

INSERT INTO public.approval_steps (workflow_id, step_order, step_name, approver_role, action) VALUES
  -- Pengeluaran kecil: 2 step
  ((SELECT id FROM public.approval_workflows WHERE name='Workflow Pengeluaran < 10jt'), 1, 'Submit', 'kepala_departemen', 'verify'),
  ((SELECT id FROM public.approval_workflows WHERE name='Workflow Pengeluaran < 10jt'), 2, 'Approve & Pay', 'bendahara', 'approve'),
  -- Pengeluaran sedang: 3 step
  ((SELECT id FROM public.approval_workflows WHERE name='Workflow Pengeluaran 10jt-100jt'), 1, 'Submit', 'kepala_departemen', 'verify'),
  ((SELECT id FROM public.approval_workflows WHERE name='Workflow Pengeluaran 10jt-100jt'), 2, 'Verify', 'manager_finance', 'verify'),
  ((SELECT id FROM public.approval_workflows WHERE name='Workflow Pengeluaran 10jt-100jt'), 3, 'Approve & Pay', 'bendahara', 'approve'),
  -- Pengeluaran besar: 4 step
  ((SELECT id FROM public.approval_workflows WHERE name='Workflow Pengeluaran > 100jt'), 1, 'Submit', 'kepala_departemen', 'verify'),
  ((SELECT id FROM public.approval_workflows WHERE name='Workflow Pengeluaran > 100jt'), 2, 'Verify', 'manager_finance', 'verify'),
  ((SELECT id FROM public.approval_workflows WHERE name='Workflow Pengeluaran > 100jt'), 3, 'Approve', 'ketua', 'approve'),
  ((SELECT id FROM public.approval_workflows WHERE name='Workflow Pengeluaran > 100jt'), 4, 'Pay', 'bendahara', 'pay'),
  -- Anggaran: 3 step
  ((SELECT id FROM public.approval_workflows WHERE name='Workflow Anggaran'), 1, 'Submit', 'kepala_departemen', 'verify'),
  ((SELECT id FROM public.approval_workflows WHERE name='Workflow Anggaran'), 2, 'Verify', 'manager_finance', 'verify'),
  ((SELECT id FROM public.approval_workflows WHERE name='Workflow Anggaran'), 3, 'Approve', 'ketua', 'approve');

-- =====================================================================
-- END OF SEED DATA
-- =====================================================================
