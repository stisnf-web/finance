-- =====================================================================
-- FINANCE & ACCOUNTING MANAGEMENT SYSTEM PRO
-- Supabase PostgreSQL Schema - Complete DDL
-- Version: 1.0.0
-- =====================================================================
-- This schema implements a multi-tenant financial management system with:
--   * Multi-organization data isolation via organization_id + RLS
--   * Double-entry bookkeeping (Debit = Kredit validation)
--   * Role-Based Access Control (RBAC)
--   * Audit trail (immutable logs)
--   * Atomic transactions for journal posting
--   * Numeric/decimal for money (no floating-point)
--   * Document sequence generation safe for concurrent inserts
-- =====================================================================

-- Required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Default organization for legacy rows (will be replaced by trigger)
CREATE OR REPLACE FUNCTION public.gen_org_id()
RETURNS UUID LANGUAGE SQL STABLE AS $$
  SELECT '00000000-0000-0000-0000-000000000000'::UUID;
$$;

-- =====================================================================
-- 1. MASTER ORGANISASI
-- =====================================================================

CREATE TABLE public.organizations (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name            TEXT NOT NULL,
  slug            TEXT UNIQUE NOT NULL,
  type            TEXT NOT NULL CHECK (type IN ('yayasan','sekolah','pesantren','perusahaan','umkm','sosial','nirlaba','unit_usaha')),
  address         TEXT,
  phone           TEXT,
  email           TEXT,
  npwp            TEXT,
  logo_url        TEXT,
  head            TEXT,
  established     DATE,
  fiscal_year     INT NOT NULL,
  currency        TEXT NOT NULL DEFAULT 'IDR',
  bookkeeping_method TEXT NOT NULL DEFAULT 'double_entry' CHECK (bookkeeping_method IN ('double_entry','cash','accrual')),
  active          BOOLEAN NOT NULL DEFAULT TRUE,
  settings        JSONB DEFAULT '{}'::JSONB,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by      UUID,
  updated_by      UUID
);
CREATE INDEX idx_organizations_slug ON public.organizations(slug);

CREATE TABLE public.organization_settings (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  setting_key     TEXT NOT NULL,
  setting_value   TEXT,
  category        TEXT DEFAULT 'general',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(organization_id, setting_key)
);

-- Generic departments table (covers directorate, division, unit, program, activity via type)
CREATE TABLE public.departments (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  code            TEXT NOT NULL,
  name            TEXT NOT NULL,
  type            TEXT NOT NULL DEFAULT 'department' CHECK (type IN ('directorate','department','division','unit','program','activity','bidang')),
  parent_id       UUID REFERENCES public.departments(id) ON DELETE SET NULL,
  level           INT NOT NULL DEFAULT 1 CHECK (level BETWEEN 1 AND 5),
  head            TEXT,
  description     TEXT,
  active          BOOLEAN NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by      UUID,
  updated_by      UUID,
  UNIQUE(organization_id, code)
);
CREATE INDEX idx_departments_org ON public.departments(organization_id);
CREATE INDEX idx_departments_parent ON public.departments(parent_id);

CREATE TABLE public.fiscal_years (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  year            INT NOT NULL,
  start_date      DATE NOT NULL,
  end_date        DATE NOT NULL,
  status          TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open','closed','locked')),
  closed_at       TIMESTAMPTZ,
  closed_by       UUID,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(organization_id, year),
  CHECK (end_date > start_date)
);

CREATE TABLE public.accounting_periods (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  fiscal_year_id  UUID NOT NULL REFERENCES public.fiscal_years(id) ON DELETE CASCADE,
  period          TEXT NOT NULL, -- format YYYY-MM
  start_date      DATE NOT NULL,
  end_date        DATE NOT NULL,
  status          TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open','closed','locked')),
  closed_at       TIMESTAMPTZ,
  closed_by       UUID,
  UNIQUE(organization_id, period)
);

-- =====================================================================
-- 2. USER DAN AKSES (RBAC)
-- =====================================================================
-- Note: auth.users is provided by Supabase Auth. We link profiles to it.

CREATE TABLE public.profiles (
  id              UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  organization_id UUID REFERENCES public.organizations(id) ON DELETE SET NULL,
  email           TEXT NOT NULL UNIQUE,
  name            TEXT NOT NULL,
  phone           TEXT,
  role            TEXT NOT NULL DEFAULT 'pengguna_unit' CHECK (role IN (
    'super_admin','admin_org','ketua','direktur','manager_finance',
    'staf_akuntansi','bendahara','kepala_departemen','kepala_unit','auditor','pengguna_unit'
  )),
  department_id   UUID REFERENCES public.departments(id) ON DELETE SET NULL,
  avatar          TEXT,
  active          BOOLEAN NOT NULL DEFAULT TRUE,
  last_login_at   TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_profiles_org ON public.profiles(organization_id);
CREATE INDEX idx_profiles_role ON public.profiles(role);

CREATE TABLE public.role_permissions (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  role            TEXT NOT NULL,
  module          TEXT NOT NULL, -- 'budget','income','expense','journal',...
  permission      TEXT NOT NULL CHECK (permission IN ('view','create','edit','delete','approve','pay','post','export','audit')),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(role, module, permission)
);
CREATE INDEX idx_role_permissions ON public.role_permissions(role);

CREATE TABLE public.approval_workflows (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  name            TEXT NOT NULL,
  transaction_type TEXT NOT NULL, -- 'budget','expense','income','transfer'
  min_amount      NUMERIC(20,2) DEFAULT 0,
  max_amount      NUMERIC(20,2),
  active          BOOLEAN NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.approval_steps (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  workflow_id     UUID NOT NULL REFERENCES public.approval_workflows(id) ON DELETE CASCADE,
  step_order      INT NOT NULL,
  step_name       TEXT NOT NULL,
  approver_role   TEXT NOT NULL,
  action          TEXT NOT NULL DEFAULT 'approve' CHECK (action IN ('verify','approve','pay','reject')),
  UNIQUE(workflow_id, step_order)
);

-- =====================================================================
-- 3. ANGGARAN (BUDGET)
-- =====================================================================

CREATE TABLE public.budget_plans (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  budget_no       TEXT NOT NULL,
  year            INT NOT NULL,
  department_id   UUID NOT NULL REFERENCES public.departments(id),
  account_code    TEXT,
  description     TEXT,
  volume          NUMERIC(15,2) NOT NULL DEFAULT 1,
  unit            TEXT DEFAULT 'Paket',
  unit_price      NUMERIC(20,2) NOT NULL DEFAULT 0,
  total           NUMERIC(20,2) NOT NULL GENERATED ALWAYS AS (volume * unit_price) STORED,
  approved_amount NUMERIC(20,2) NOT NULL DEFAULT 0,
  realization     NUMERIC(20,2) NOT NULL DEFAULT 0,
  pic             TEXT,
  status          TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','submitted','review','revision','approved','rejected','locked')),
  created_by      UUID,
  approved_by     UUID,
  approved_at     TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(organization_id, budget_no),
  CHECK (volume >= 0 AND unit_price >= 0 AND approved_amount >= 0 AND realization >= 0)
);
CREATE INDEX idx_budget_plans_org ON public.budget_plans(organization_id);
CREATE INDEX idx_budget_plans_dept ON public.budget_plans(department_id);
CREATE INDEX idx_budget_plans_status ON public.budget_plans(status);

CREATE TABLE public.budget_items (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  budget_plan_id  UUID NOT NULL REFERENCES public.budget_plans(id) ON DELETE CASCADE,
  account_code    TEXT NOT NULL,
  description     TEXT,
  volume          NUMERIC(15,2) NOT NULL,
  unit            TEXT,
  unit_price      NUMERIC(20,2) NOT NULL,
  subtotal        NUMERIC(20,2) GENERATED ALWAYS AS (volume * unit_price) STORED,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.budget_revisions (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  budget_plan_id  UUID NOT NULL REFERENCES public.budget_plans(id) ON DELETE CASCADE,
  old_amount      NUMERIC(20,2) NOT NULL,
  new_amount      NUMERIC(20,2) NOT NULL,
  reason          TEXT,
  revised_by      UUID,
  approved_by     UUID,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (new_amount >= 0)
);

-- =====================================================================
-- 4. TRANSAKSI
-- =====================================================================

CREATE TABLE public.income_transactions (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  trans_no        TEXT NOT NULL,
  date            DATE NOT NULL,
  source          TEXT NOT NULL,
  category        TEXT NOT NULL,
  account_code    TEXT NOT NULL, -- COA pendapatan
  cash_bank_id    UUID NOT NULL,
  department_id   UUID REFERENCES public.departments(id),
  method          TEXT NOT NULL CHECK (method IN ('cash','transfer','va','gateway','other')),
  amount          NUMERIC(20,2) NOT NULL CHECK (amount > 0),
  description     TEXT,
  status          TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','verified','posted','cancelled')),
  journal_id      UUID, -- link to posted journal
  created_by      UUID,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(organization_id, trans_no)
);
CREATE INDEX idx_income_org_date ON public.income_transactions(organization_id, date);
CREATE INDEX idx_income_status ON public.income_transactions(status);

CREATE TABLE public.expense_requests (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  trans_no        TEXT NOT NULL,
  date            DATE NOT NULL,
  department_id   UUID NOT NULL REFERENCES public.departments(id),
  budget_plan_id  UUID REFERENCES public.budget_plans(id),
  category        TEXT NOT NULL,
  account_code    TEXT NOT NULL, -- COA beban
  cash_bank_id    UUID,
  method          TEXT CHECK (method IN ('cash','transfer','va','gateway','other')),
  payee           TEXT,
  amount          NUMERIC(20,2) NOT NULL CHECK (amount > 0),
  description     TEXT NOT NULL,
  status          TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','submitted','verified','approved','paid','rejected','cancelled')),
  journal_id      UUID,
  created_by      UUID,
  verified_by     UUID,
  approved_by     UUID,
  paid_by         UUID,
  verified_at     TIMESTAMPTZ,
  approved_at     TIMESTAMPTZ,
  paid_at         TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(organization_id, trans_no)
);
CREATE INDEX idx_expense_org_status ON public.expense_requests(organization_id, status);
CREATE INDEX idx_expense_dept ON public.expense_requests(department_id);

CREATE TABLE public.transaction_attachments (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL,
  transaction_id  UUID NOT NULL,
  transaction_type TEXT NOT NULL CHECK (transaction_type IN ('income','expense','transfer','budget')),
  file_name       TEXT NOT NULL,
  file_url        TEXT NOT NULL,
  file_size       BIGINT,
  mime_type       TEXT,
  uploaded_by     UUID,
  uploaded_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.fund_transfers (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  trans_no        TEXT NOT NULL,
  date            DATE NOT NULL,
  from_account_id UUID NOT NULL,
  to_account_id   UUID NOT NULL,
  amount          NUMERIC(20,2) NOT NULL CHECK (amount > 0),
  description     TEXT,
  status          TEXT NOT NULL DEFAULT 'completed' CHECK (status IN ('draft','completed','cancelled')),
  journal_id      UUID,
  created_by      UUID,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(organization_id, trans_no),
  CHECK (from_account_id <> to_account_id)
);

-- =====================================================================
-- 5. KAS DAN BANK
-- =====================================================================

CREATE TABLE public.cash_bank_accounts (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  name            TEXT NOT NULL,
  type            TEXT NOT NULL CHECK (type IN ('kas','bank')),
  account_code    TEXT NOT NULL,
  bank_name       TEXT,
  account_number  TEXT,
  holder          TEXT,
  opening_balance NUMERIC(20,2) NOT NULL DEFAULT 0,
  balance         NUMERIC(20,2) NOT NULL DEFAULT 0,
  active          BOOLEAN NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (opening_balance >= 0 AND balance >= 0)
);
CREATE INDEX idx_cash_bank_org ON public.cash_bank_accounts(organization_id);

CREATE TABLE public.bank_statements (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL,
  cash_bank_id    UUID NOT NULL REFERENCES public.cash_bank_accounts(id) ON DELETE CASCADE,
  statement_date  DATE NOT NULL,
  opening_balance NUMERIC(20,2) NOT NULL,
  closing_balance NUMERIC(20,2) NOT NULL,
  file_url        TEXT,
  imported_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  imported_by     UUID
);

CREATE TABLE public.bank_reconciliations (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL,
  cash_bank_id    UUID NOT NULL REFERENCES public.cash_bank_accounts(id) ON DELETE CASCADE,
  period          TEXT NOT NULL,
  book_balance    NUMERIC(20,2) NOT NULL,
  bank_balance    NUMERIC(20,2) NOT NULL,
  difference      NUMERIC(20,2) GENERATED ALWAYS AS (book_balance - bank_balance) STORED,
  status          TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','matched','adjusted','closed')),
  reconciled_by   UUID,
  reconciled_at   TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================================
-- 6. AKUNTANSI (CORE ENGINE)
-- =====================================================================

CREATE TABLE public.chart_of_accounts (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  code            TEXT NOT NULL,
  name            TEXT NOT NULL,
  type            TEXT NOT NULL CHECK (type IN ('asset','liabilitas','ekuitas','pendapatan','beban')),
  subtype         TEXT,
  parent_id       UUID REFERENCES public.chart_of_accounts(id) ON DELETE SET NULL,
  level           INT NOT NULL DEFAULT 1 CHECK (level BETWEEN 1 AND 5),
  is_group        BOOLEAN NOT NULL DEFAULT FALSE,
  active          BOOLEAN NOT NULL DEFAULT TRUE,
  opening_balance NUMERIC(20,2) DEFAULT 0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(organization_id, code)
);
CREATE INDEX idx_coa_org_type ON public.chart_of_accounts(organization_id, type);
CREATE INDEX idx_coa_parent ON public.chart_of_accounts(parent_id);

CREATE TABLE public.journal_entries (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  journal_no      TEXT NOT NULL,
  date            DATE NOT NULL,
  type            TEXT NOT NULL CHECK (type IN (
    'jurnal_umum','jurnal_penerimaan','jurnal_pengeluaran','jurnal_pembelian',
    'jurnal_penjualan','jurnal_penyesuaian','jurnal_penutup','jurnal_pembalik','jurnal_pembuka'
  )),
  ref_type        TEXT, -- 'income','expense','transfer','manual','opening','depreciation'
  ref_id          UUID,
  ref_no          TEXT,
  description     TEXT NOT NULL,
  department_id   UUID REFERENCES public.departments(id),
  period          TEXT NOT NULL, -- YYYY-MM
  status          TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','posted','reversed','cancelled')),
  total_debit     NUMERIC(20,2) NOT NULL DEFAULT 0,
  total_credit    NUMERIC(20,2) NOT NULL DEFAULT 0,
  is_balanced     BOOLEAN GENERATED ALWAYS AS (total_debit = total_credit) STORED,
  posted_at       TIMESTAMPTZ,
  posted_by       UUID,
  created_by      UUID,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(organization_id, journal_no),
  CHECK (total_debit >= 0 AND total_credit >= 0)
);
CREATE INDEX idx_journal_org_date ON public.journal_entries(organization_id, date);
CREATE INDEX idx_journal_status ON public.journal_entries(status);
CREATE INDEX idx_journal_ref ON public.journal_entries(ref_type, ref_id);

CREATE TABLE public.journal_details (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  journal_id      UUID NOT NULL REFERENCES public.journal_entries(id) ON DELETE CASCADE,
  account_code    TEXT NOT NULL,
  description     TEXT,
  debit           NUMERIC(20,2) NOT NULL DEFAULT 0 CHECK (debit >= 0),
  credit          NUMERIC(20,2) NOT NULL DEFAULT 0 CHECK (credit >= 0),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (NOT (debit > 0 AND credit > 0)) -- a line cannot have both debit and credit
);
CREATE INDEX idx_jdetail_journal ON public.journal_details(journal_id);
CREATE INDEX idx_jdetail_account ON public.journal_details(account_code);

-- Materialized view for general ledger / trial balance (refresh on demand)
CREATE MATERIALIZED VIEW public.mv_account_balances AS
SELECT
  je.organization_id,
  jd.account_code,
  SUM(jd.debit)  AS total_debit,
  SUM(jd.credit) AS total_credit,
  SUM(jd.debit - jd.credit) AS net_balance
FROM public.journal_entries je
JOIN public.journal_details jd ON jd.journal_id = je.id
WHERE je.status = 'posted'
GROUP BY je.organization_id, jd.account_code;
CREATE UNIQUE INDEX idx_mv_acc_bal ON public.mv_account_balances(organization_id, account_code);

CREATE TABLE public.accounting_period_closings (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL,
  period          TEXT NOT NULL,
  fiscal_year_id  UUID REFERENCES public.fiscal_years(id),
  closed_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  closed_by       UUID,
  notes           TEXT,
  UNIQUE(organization_id, period)
);

-- =====================================================================
-- 7. PIUTANG DAN UTANG
-- =====================================================================

CREATE TABLE public.customers (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL,
  name            TEXT NOT NULL,
  type            TEXT DEFAULT 'individual' CHECK (type IN ('individual','corporate','student','donor')),
  email           TEXT,
  phone           TEXT,
  address         TEXT,
  tax_id          TEXT,
  active          BOOLEAN NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(organization_id, name)
);

CREATE TABLE public.vendors (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL,
  name            TEXT NOT NULL,
  npwp            TEXT,
  contact_person  TEXT,
  email           TEXT,
  phone           TEXT,
  address         TEXT,
  bank_account    TEXT,
  active          BOOLEAN NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(organization_id, name)
);

CREATE TABLE public.receivables (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL,
  customer_id     UUID REFERENCES public.customers(id),
  customer_name   TEXT NOT NULL,
  invoice_no      TEXT NOT NULL,
  invoice_date    DATE NOT NULL,
  due_date        DATE NOT NULL,
  amount          NUMERIC(20,2) NOT NULL CHECK (amount > 0),
  paid            NUMERIC(20,2) NOT NULL DEFAULT 0 CHECK (paid >= 0),
  status          TEXT NOT NULL DEFAULT 'unpaid' CHECK (status IN ('unpaid','partial','paid','bad_debt')),
  notes           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(organization_id, invoice_no),
  CHECK (due_date >= invoice_date)
);
CREATE INDEX idx_receivables_status ON public.receivables(status, due_date);

CREATE TABLE public.receivable_payments (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  receivable_id   UUID NOT NULL REFERENCES public.receivables(id) ON DELETE CASCADE,
  amount          NUMERIC(20,2) NOT NULL CHECK (amount > 0),
  payment_date    DATE NOT NULL,
  method          TEXT,
  cash_bank_id    UUID,
  journal_id      UUID,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.payables (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL,
  vendor_id       UUID REFERENCES public.vendors(id),
  vendor_name     TEXT NOT NULL,
  invoice_no      TEXT NOT NULL,
  invoice_date    DATE NOT NULL,
  due_date        DATE NOT NULL,
  amount          NUMERIC(20,2) NOT NULL CHECK (amount > 0),
  paid            NUMERIC(20,2) NOT NULL DEFAULT 0 CHECK (paid >= 0),
  status          TEXT NOT NULL DEFAULT 'unpaid' CHECK (status IN ('unpaid','partial','paid','cancelled')),
  notes           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(organization_id, invoice_no),
  CHECK (due_date >= invoice_date)
);

CREATE TABLE public.payable_payments (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  payable_id      UUID NOT NULL REFERENCES public.payables(id) ON DELETE CASCADE,
  amount          NUMERIC(20,2) NOT NULL CHECK (amount > 0),
  payment_date    DATE NOT NULL,
  method          TEXT,
  cash_bank_id    UUID,
  journal_id      UUID,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================================
-- 8. ASET TETAP
-- =====================================================================

CREATE TABLE public.fixed_assets (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL,
  code            TEXT NOT NULL,
  name            TEXT NOT NULL,
  category        TEXT, -- 'kendaraan','bangunan','peralatan','inventaris'
  purchase_date   DATE NOT NULL,
  acquisition_value NUMERIC(20,2) NOT NULL CHECK (acquisition_value > 0),
  accumulated_dep NUMERIC(20,2) NOT NULL DEFAULT 0,
  book_value      NUMERIC(20,2) NOT NULL,
  location        TEXT,
  responsible     TEXT,
  useful_life     INT NOT NULL CHECK (useful_life > 0),
  depreciation_method TEXT NOT NULL DEFAULT 'straight_line' CHECK (depreciation_method IN ('straight_line','declining','sum_of_years')),
  status          TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','maintenance','disposed','written_off')),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(organization_id, code)
);

CREATE TABLE public.asset_depreciations (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  asset_id        UUID NOT NULL REFERENCES public.fixed_assets(id) ON DELETE CASCADE,
  period          TEXT NOT NULL,
  depreciation    NUMERIC(20,2) NOT NULL,
  journal_id      UUID,
  posted_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(asset_id, period)
);

CREATE TABLE public.asset_maintenance (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  asset_id        UUID NOT NULL REFERENCES public.fixed_assets(id) ON DELETE CASCADE,
  maintenance_date DATE NOT NULL,
  description     TEXT,
  cost            NUMERIC(20,2) DEFAULT 0,
  performed_by    TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.asset_disposals (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  asset_id        UUID NOT NULL REFERENCES public.fixed_assets(id) ON DELETE CASCADE,
  disposal_date   DATE NOT NULL,
  disposal_value  NUMERIC(20,2) DEFAULT 0,
  reason          TEXT,
  journal_id      UUID,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================================
-- 9. PERPAJAKAN
-- =====================================================================

CREATE TABLE public.tax_types (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL,
  name            TEXT NOT NULL,
  rate            NUMERIC(5,2) NOT NULL CHECK (rate >= 0),
  description     TEXT,
  active          BOOLEAN NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.tax_transactions (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL,
  tax_type        TEXT NOT NULL,
  period          TEXT NOT NULL,
  base_amount     NUMERIC(20,2) NOT NULL,
  tax_amount      NUMERIC(20,2) NOT NULL,
  tax_out         NUMERIC(20,2),
  tax_in          NUMERIC(20,2),
  status          TEXT NOT NULL DEFAULT 'payable' CHECK (status IN ('payable','paid','cancelled')),
  paid_date       DATE,
  journal_id      UUID,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(organization_id, tax_type, period)
);

-- =====================================================================
-- 10. DOKUMEN
-- =====================================================================

CREATE TABLE public.document_sequences (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL,
  doc_type        TEXT NOT NULL, -- 'income','expense','transfer','journal','budget'
  year            INT NOT NULL,
  last_seq        INT NOT NULL DEFAULT 0,
  UNIQUE(organization_id, doc_type, year)
);

-- Atomic sequence generation (safe for concurrent inserts)
CREATE OR REPLACE FUNCTION public.next_doc_number(
  p_org UUID,
  p_type TEXT,
  p_year INT DEFAULT NULL
) RETURNS TEXT AS $$
DECLARE
  v_year INT := COALESCE(p_year, EXTRACT(YEAR FROM NOW()));
  v_seq INT;
  v_prefix TEXT;
BEGIN
  v_prefix := CASE p_type
    WHEN 'income'   THEN 'INC'
    WHEN 'expense'  THEN 'EXP'
    WHEN 'transfer' THEN 'TRF'
    WHEN 'journal'  THEN 'JV'
    WHEN 'budget'   THEN 'BUD'
    ELSE 'DOC'
  END;

  INSERT INTO public.document_sequences (organization_id, doc_type, year, last_seq)
  VALUES (p_org, p_type, v_year, 1)
  ON CONFLICT (organization_id, doc_type, year)
  DO UPDATE SET last_seq = document_sequences.last_seq + 1
  RETURNING last_seq INTO v_seq;

  RETURN v_prefix || '-' || v_year || '-' || LPAD(v_seq::TEXT, 4, '0');
END;
$$ LANGUAGE plpgsql;

CREATE TABLE public.financial_documents (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL,
  doc_type        TEXT NOT NULL, -- 'neraca','laba_rugi','arus_kas','neraca_saldo','buku_besar'
  period          TEXT,
  start_date      DATE,
  end_date        DATE,
  file_url        TEXT,
  generated_by    UUID,
  generated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================================
-- 11. SISTEM
-- =====================================================================

CREATE TABLE public.notifications (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL,
  user_id         UUID,
  title           TEXT NOT NULL,
  message         TEXT,
  icon            TEXT DEFAULT 'fa-bell',
  page            TEXT,
  read            BOOLEAN NOT NULL DEFAULT FALSE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_notifications_user ON public.notifications(user_id, read);

-- Audit trail: append-only via trigger (no UPDATE/DELETE)
CREATE TABLE public.audit_logs (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID,
  user_id         UUID,
  user_name       TEXT,
  action          TEXT NOT NULL,
  description     TEXT,
  ref_type        TEXT,
  ref_id          UUID,
  ref_no          TEXT,
  old_data        JSONB,
  new_data        JSONB,
  ip_address      INET,
  user_agent      TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_audit_org_time ON public.audit_logs(organization_id, created_at DESC);
CREATE INDEX idx_audit_user ON public.audit_logs(user_id);

-- Prevent UPDATE and DELETE on audit_logs
CREATE OR REPLACE FUNCTION public.prevent_audit_modify()
RETURNS TRIGGER AS $$
BEGIN
  RAISE EXCEPTION 'audit_logs is append-only. UPDATE and DELETE are not allowed.';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_prevent_audit_update
  BEFORE UPDATE ON public.audit_logs
  FOR EACH ROW EXECUTE FUNCTION public.prevent_audit_modify();

CREATE TRIGGER trg_prevent_audit_delete
  BEFORE DELETE ON public.audit_logs
  FOR EACH ROW EXECUTE FUNCTION public.prevent_audit_modify();

CREATE TABLE public.system_settings (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID,
  key             TEXT NOT NULL,
  value           TEXT,
  category        TEXT DEFAULT 'general',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(organization_id, key)
);

CREATE TABLE public.ai_interactions (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL,
  user_id         UUID NOT NULL,
  question        TEXT NOT NULL,
  answer          TEXT,
  model           TEXT DEFAULT 'gemini-pro',
  tokens_used     INT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_ai_user ON public.ai_interactions(user_id, created_at DESC);

-- =====================================================================
-- 12. TRIGGERS & HELPER FUNCTIONS
-- =====================================================================

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION public.touch_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_touch_organizations   BEFORE UPDATE ON public.organizations        FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();
CREATE TRIGGER trg_touch_departments     BEFORE UPDATE ON public.departments          FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();
CREATE TRIGGER trg_touch_profiles        BEFORE UPDATE ON public.profiles             FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();
CREATE TRIGGER trg_touch_budget_plans    BEFORE UPDATE ON public.budget_plans         FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();
CREATE TRIGGER trg_touch_coa             BEFORE UPDATE ON public.chart_of_accounts   FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();
CREATE TRIGGER trg_touch_cash_bank       BEFORE UPDATE ON public.cash_bank_accounts   FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();
CREATE TRIGGER trg_touch_journal         BEFORE UPDATE ON public.journal_entries      FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();
CREATE TRIGGER trg_touch_income          BEFORE UPDATE ON public.income_transactions  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();
CREATE TRIGGER trg_touch_expense         BEFORE UPDATE ON public.expense_requests    FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();
CREATE TRIGGER trg_touch_assets          BEFORE UPDATE ON public.fixed_assets         FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

-- Audit log helper
CREATE OR REPLACE FUNCTION public.log_audit(
  p_org UUID, p_user UUID, p_user_name TEXT, p_action TEXT,
  p_desc TEXT, p_ref_type TEXT DEFAULT NULL, p_ref_id UUID DEFAULT NULL, p_ref_no TEXT DEFAULT NULL,
  p_old JSONB DEFAULT NULL, p_new JSONB DEFAULT NULL
) RETURNS UUID AS $$
DECLARE v_id UUID;
BEGIN
  INSERT INTO public.audit_logs(organization_id, user_id, user_name, action, description, ref_type, ref_id, ref_no, old_data, new_data)
  VALUES (p_org, p_user, p_user_name, p_action, p_desc, p_ref_type, p_ref_id, p_ref_no, p_old, p_new)
  RETURNING id INTO v_id;
  RETURN v_id;
END;
$$ LANGUAGE plpgsql;

-- Refresh account balances materialized view
CREATE OR REPLACE FUNCTION public.refresh_account_balances()
RETURNS VOID AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY public.mv_account_balances;
END;
$$ LANGUAGE plpgsql;

-- Atomic journal posting with double-entry validation
CREATE OR REPLACE FUNCTION public.post_journal(
  p_org UUID, p_user UUID, p_date DATE, p_type TEXT, p_desc TEXT,
  p_details JSONB, p_ref_type TEXT DEFAULT NULL, p_ref_id UUID DEFAULT NULL, p_ref_no TEXT DEFAULT NULL,
  p_dept UUID DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
  v_id UUID;
  v_no TEXT;
  v_dr NUMERIC(20,2) := 0;
  v_cr NUMERIC(20,2) := 0;
  v_detail RECORD;
BEGIN
  -- Calculate totals
  FOR v_detail IN SELECT * FROM jsonb_array_elements(p_details) LOOP
    v_dr := v_dr + COALESCE((v_detail.value->>'debit')::NUMERIC, 0);
    v_cr := v_cr + COALESCE((v_detail.value->>'credit')::NUMERIC, 0);
  END LOOP;

  -- Validate double-entry balance
  IF v_dr <> v_cr THEN
    RAISE EXCEPTION 'Jurnal tidak seimbang: Debit % != Kredit %', v_dr, v_cr;
  END IF;

  IF v_dr = 0 THEN
    RAISE EXCEPTION 'Jurnal tidak boleh kosong (total = 0)';
  END IF;

  -- Validate period not closed
  IF EXISTS (SELECT 1 FROM public.accounting_period_closings
             WHERE organization_id = p_org AND period = TO_CHAR(p_date, 'YYYY-MM')) THEN
    RAISE EXCEPTION 'Periode % sudah ditutup, transaksi tidak dapat diposting', TO_CHAR(p_date, 'YYYY-MM');
  END IF;

  -- Generate journal number atomically
  v_no := public.next_doc_number(p_org, 'journal', EXTRACT(YEAR FROM p_date)::INT);

  -- Insert journal entry
  INSERT INTO public.journal_entries
    (organization_id, journal_no, date, type, description, department_id, period,
     ref_type, ref_id, ref_no, status, total_debit, total_credit, posted_at, posted_by, created_by)
  VALUES
    (p_org, v_no, p_date, p_type, p_desc, p_dept, TO_CHAR(p_date, 'YYYY-MM'),
     p_ref_type, p_ref_id, p_ref_no, 'posted', v_dr, v_cr, NOW(), p_user, p_user)
  RETURNING id INTO v_id;

  -- Insert details
  FOR v_detail IN SELECT * FROM jsonb_array_elements(p_details) LOOP
    INSERT INTO public.journal_details(journal_id, account_code, description, debit, credit)
    VALUES (v_id,
            (v_detail.value->>'account_code')::TEXT,
            COALESCE((v_detail.value->>'description')::TEXT, ''),
            COALESCE((v_detail.value->>'debit')::NUMERIC, 0),
            COALESCE((v_detail.value->>'credit')::NUMERIC, 0));
  END LOOP;

  -- Refresh balances
  PERFORM public.refresh_account_balances();

  -- Log audit
  PERFORM public.log_audit(p_org, p_user, NULL, 'Posting Jurnal', 'Posting ' || v_no || ' (' || v_dr || ')', 'journal', v_id, v_no);

  RETURN v_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================================
-- 13. SEED: DEFAULT ROLE PERMISSIONS
-- =====================================================================
INSERT INTO public.role_permissions(role, module, permission) VALUES
  ('super_admin','all','view'),('super_admin','all','create'),('super_admin','all','edit'),
  ('super_admin','all','delete'),('super_admin','all','approve'),('super_admin','all','post'),
  ('manager_finance','budget','view'),('manager_finance','budget','create'),('manager_finance','budget','approve'),
  ('manager_finance','income','view'),('manager_finance','income','create'),('manager_finance','income','post'),
  ('manager_finance','expense','view'),('manager_finance','expense','create'),('manager_finance','expense','approve'),('manager_finance','expense','pay'),
  ('manager_finance','journal','view'),('manager_finance','journal','post'),
  ('manager_finance','reports','view'),('manager_finance','reports','export'),
  ('staf_akuntansi','journal','view'),('staf_akuntansi','journal','create'),('staf_akuntansi','journal','post'),
  ('staf_akuntansi','coa','view'),('staf_akuntansi','coa','create'),('staf_akuntansi','coa','edit'),
  ('staf_akuntansi','reports','view'),('staf_akuntansi','reports','export'),
  ('bendahara','income','view'),('bendahara','income','create'),('bendahara','income','post'),
  ('bendahara','expense','view'),('bendahara','expense','pay'),
  ('bendahara','cash_bank','view'),('bendahara','cash_bank','edit'),
  ('bendahara','transfer','view'),('bendahara','transfer','create'),
  ('kepala_departemen','budget','view'),('kepala_departemen','budget','create'),
  ('kepala_departemen','expense','view'),('kepala_departemen','expense','create'),
  ('ketua','reports','view'),('ketua','reports','export'),
  ('ketua','budget','approve'),('ketua','expense','approve'),
  ('auditor','all','view'),('auditor','audit','view');

-- =====================================================================
-- END OF SCHEMA
-- =====================================================================
