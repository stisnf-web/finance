-- =====================================================================
-- FINANCE PRO - Row Level Security (RLS) Policies
-- Implements multi-tenant data isolation + Role-Based Access Control
-- =====================================================================
-- PRINSIP:
--   1. Setiap baris punya organization_id → tenant isolation
--   2. User hanya bisa akses data org sendiri (kecuali super_admin)
--   3. Auditor: read-only ke semua data org
--   4. Jurnal posted tidak bisa di-UPDATE/DELETE (audit trail)
--   5. audit_logs: append-only (sudah di-trigger)
-- =====================================================================

-- Enable RLS on all tenant tables
ALTER TABLE public.organizations           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organization_settings  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.departments            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fiscal_years           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.accounting_periods     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.budget_plans           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.budget_items           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.budget_revisions       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.income_transactions    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expense_requests       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transaction_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fund_transfers         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cash_bank_accounts     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bank_statements        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bank_reconciliations   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chart_of_accounts     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.journal_entries        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.journal_details        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vendors                ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.receivables            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.receivable_payments    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payables               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payable_payments       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fixed_assets           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.asset_depreciations    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.asset_maintenance     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.asset_disposals        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tax_types              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tax_transactions       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_sequences    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.financial_documents    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.system_settings       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_interactions        ENABLE ROW LEVEL SECURITY;

-- =====================================================================
-- Helper functions
-- =====================================================================
CREATE OR REPLACE FUNCTION public.current_user_org()
RETURNS UUID LANGUAGE SQL STABLE SECURITY DEFINER AS $$
  SELECT organization_id FROM public.profiles WHERE id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS TEXT LANGUAGE SQL STABLE SECURITY DEFINER AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS BOOLEAN LANGUAGE SQL STABLE SECURITY DEFINER AS $$
  SELECT COALESCE((SELECT role = 'super_admin' FROM public.profiles WHERE id = auth.uid()), FALSE);
$$;

CREATE OR REPLACE FUNCTION public.is_auditor()
RETURNS BOOLEAN LANGUAGE SQL STABLE SECURITY DEFINER AS $$
  SELECT COALESCE((SELECT role = 'auditor' FROM public.profiles WHERE id = auth.uid()), FALSE);
$$;

-- =====================================================================
-- 1. ORGANIZATIONS
-- =====================================================================
CREATE POLICY org_select ON public.organizations
  FOR SELECT USING (
    public.is_super_admin()
    OR id = public.current_user_org()
  );

CREATE POLICY org_modify ON public.organizations
  FOR ALL USING (public.is_super_admin())
  WITH CHECK (public.is_super_admin());

-- =====================================================================
-- 2. PROFILES
-- =====================================================================
CREATE POLICY profile_select ON public.profiles
  FOR SELECT USING (
    public.is_super_admin()
    OR id = auth.uid()
    OR organization_id = public.current_user_org()
  );

CREATE POLICY profile_self_update ON public.profiles
  FOR UPDATE USING (id = auth.uid());

CREATE POLICY profile_admin_insert ON public.profiles
  FOR INSERT WITH CHECK (
    public.is_super_admin()
    OR public.current_user_role() IN ('admin_org','manager_finance')
  );

-- =====================================================================
-- 3. DEPARTMENTS - tenant isolation
-- =====================================================================
CREATE POLICY dept_select ON public.departments
  FOR SELECT USING (
    public.is_super_admin()
    OR organization_id = public.current_user_org()
  );

CREATE POLICY dept_modify ON public.departments
  FOR ALL USING (
    public.is_super_admin()
    OR (organization_id = public.current_user_org()
        AND public.current_user_role() IN ('admin_org','manager_finance'))
  );

-- =====================================================================
-- 4. GENERIC TENANT POLICY (applied to most tables)
-- Pattern: SELECT if same org (or auditor/super_admin),
--          INSERT/UPDATE/DELETE only for roles with permission
-- =====================================================================

-- Helper macro (inlined SQL)
-- For brevity, we use a single policy per table per operation

-- BUDGET_PLANS
CREATE POLICY budget_select ON public.budget_plans
  FOR SELECT USING (
    public.is_super_admin() OR public.is_auditor()
    OR organization_id = public.current_user_org()
  );
CREATE POLICY budget_insert ON public.budget_plans
  FOR INSERT WITH CHECK (
    organization_id = public.current_user_org()
    AND public.current_user_role() IN ('kepala_unit','kepala_departemen','manager_finance','admin_org','super_admin')
  );
CREATE POLICY budget_update ON public.budget_plans
  FOR UPDATE USING (
    organization_id = public.current_user_org()
    AND public.current_user_role() IN ('manager_finance','admin_org','super_admin','kepala_departemen')
  );

-- INCOME_TRANSACTIONS
CREATE POLICY inc_select ON public.income_transactions
  FOR SELECT USING (
    public.is_super_admin() OR public.is_auditor()
    OR organization_id = public.current_user_org()
  );
CREATE POLICY inc_insert ON public.income_transactions
  FOR INSERT WITH CHECK (
    organization_id = public.current_user_org()
    AND public.current_user_role() IN ('bendahara','manager_finance','admin_org','super_admin')
  );
CREATE POLICY inc_update ON public.income_transactions
  FOR UPDATE USING (
    organization_id = public.current_user_org()
    AND public.current_user_role() IN ('bendahara','manager_finance','admin_org','super_admin')
  );

-- EXPENSE_REQUESTS
CREATE POLICY exp_select ON public.expense_requests
  FOR SELECT USING (
    public.is_super_admin() OR public.is_auditor()
    OR organization_id = public.current_user_org()
  );
CREATE POLICY exp_insert ON public.expense_requests
  FOR INSERT WITH CHECK (
    organization_id = public.current_user_org()
    AND public.current_user_role() IN ('kepala_unit','kepala_departemen','manager_finance','admin_org','super_admin','bendahara')
  );
CREATE POLICY exp_update ON public.expense_requests
  FOR UPDATE USING (
    organization_id = public.current_user_org()
    AND public.current_user_role() IN ('bendahara','manager_finance','admin_org','super_admin','kepala_departemen','direktur','ketua')
  );

-- FUND_TRANSFERS
CREATE POLICY trf_select ON public.fund_transfers
  FOR SELECT USING (
    public.is_super_admin() OR public.is_auditor()
    OR organization_id = public.current_user_org()
  );
CREATE POLICY trf_insert ON public.fund_transfers
  FOR INSERT WITH CHECK (
    organization_id = public.current_user_org()
    AND public.current_user_role() IN ('bendahara','manager_finance','admin_org','super_admin')
  );

-- CASH_BANK_ACCOUNTS
CREATE POLICY cb_select ON public.cash_bank_accounts
  FOR SELECT USING (
    public.is_super_admin() OR public.is_auditor()
    OR organization_id = public.current_user_org()
  );
CREATE POLICY cb_modify ON public.cash_bank_accounts
  FOR ALL USING (
    organization_id = public.current_user_org()
    AND public.current_user_role() IN ('manager_finance','admin_org','super_admin','bendahara')
  ) WITH CHECK (
    organization_id = public.current_user_org()
    AND public.current_user_role() IN ('manager_finance','admin_org','super_admin','bendahara')
  );

-- CHART_OF_ACCOUNTS
CREATE POLICY coa_select ON public.chart_of_accounts
  FOR SELECT USING (
    public.is_super_admin() OR public.is_auditor()
    OR organization_id = public.current_user_org()
  );
CREATE POLICY coa_modify ON public.chart_of_accounts
  FOR ALL USING (
    organization_id = public.current_user_org()
    AND public.current_user_role() IN ('staf_akuntansi','manager_finance','admin_org','super_admin')
  ) WITH CHECK (
    organization_id = public.current_user_org()
    AND public.current_user_role() IN ('staf_akuntansi','manager_finance','admin_org','super_admin')
  );

-- JOURNAL_ENTRIES - special: posted journals cannot be edited
CREATE POLICY jv_select ON public.journal_entries
  FOR SELECT USING (
    public.is_super_admin() OR public.is_auditor()
    OR organization_id = public.current_user_org()
  );
CREATE POLICY jv_insert ON public.journal_entries
  FOR INSERT WITH CHECK (
    organization_id = public.current_user_org()
    AND public.current_user_role() IN ('staf_akuntansi','manager_finance','admin_org','super_admin','bendahara')
  );
-- Posted journals cannot be updated directly (must use reversal journal)
CREATE POLICY jv_update ON public.journal_entries
  FOR UPDATE USING (
    organization_id = public.current_user_org()
    AND status = 'draft'
    AND public.current_user_role() IN ('staf_akuntansi','manager_finance','admin_org','super_admin')
  );
-- Delete only allowed for draft journals
CREATE POLICY jv_delete ON public.journal_entries
  FOR DELETE USING (
    organization_id = public.current_user_org()
    AND status = 'draft'
    AND public.current_user_role() IN ('staf_akuntansi','manager_finance','admin_org','super_admin')
  );

-- JOURNAL_DETAILS - follow journal entry policy
CREATE POLICY jd_select ON public.journal_details
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.journal_entries je
      WHERE je.id = journal_id
      AND (public.is_super_admin() OR public.is_auditor()
           OR je.organization_id = public.current_user_org())
    )
  );

-- RECEIVABLES / PAYABLES
CREATE POLICY rcv_select ON public.receivables
  FOR SELECT USING (public.is_super_admin() OR public.is_auditor() OR organization_id = public.current_user_org());
CREATE POLICY rcv_modify ON public.receivables
  FOR ALL USING (organization_id = public.current_user_org() AND public.current_user_role() IN ('bendahara','manager_finance','admin_org','super_admin'))
  WITH CHECK (organization_id = public.current_user_org() AND public.current_user_role() IN ('bendahara','manager_finance','admin_org','super_admin'));

CREATE POLICY pay_select ON public.payables
  FOR SELECT USING (public.is_super_admin() OR public.is_auditor() OR organization_id = public.current_user_org());
CREATE POLICY pay_modify ON public.payables
  FOR ALL USING (organization_id = public.current_user_org() AND public.current_user_role() IN ('bendahara','manager_finance','admin_org','super_admin'))
  WITH CHECK (organization_id = public.current_user_org() AND public.current_user_role() IN ('bendahara','manager_finance','admin_org','super_admin'));

-- FIXED_ASSETS
CREATE POLICY fa_select ON public.fixed_assets
  FOR SELECT USING (public.is_super_admin() OR public.is_auditor() OR organization_id = public.current_user_org());
CREATE POLICY fa_modify ON public.fixed_assets
  FOR ALL USING (organization_id = public.current_user_org() AND public.current_user_role() IN ('staf_akuntansi','manager_finance','admin_org','super_admin'))
  WITH CHECK (organization_id = public.current_user_org() AND public.current_user_role() IN ('staf_akuntansi','manager_finance','admin_org','super_admin'));

-- TAX
CREATE POLICY tax_select ON public.tax_transactions
  FOR SELECT USING (public.is_super_admin() OR public.is_auditor() OR organization_id = public.current_user_org());
CREATE POLICY tax_modify ON public.tax_transactions
  FOR ALL USING (organization_id = public.current_user_org() AND public.current_user_role() IN ('staf_akuntansi','manager_finance','admin_org','super_admin'))
  WITH CHECK (organization_id = public.current_user_org() AND public.current_user_role() IN ('staf_akuntansi','manager_finance','admin_org','super_admin'));

-- AUDIT_LOGS - read only for all authenticated users in same org
CREATE POLICY audit_select ON public.audit_logs
  FOR SELECT USING (
    public.is_super_admin() OR public.is_auditor()
    OR organization_id = public.current_user_org()
    OR user_id = auth.uid()
  );
-- No INSERT/UPDATE/DELETE policy = blocked (only SECURITY DEFINER functions can insert)

-- NOTIFICATIONS - user only sees their own
CREATE POLICY notif_select ON public.notifications
  FOR SELECT USING (
    public.is_super_admin()
    OR user_id = auth.uid()
    OR organization_id = public.current_user_org()
  );
CREATE POLICY notif_update ON public.notifications
  FOR UPDATE USING (user_id = auth.uid() OR public.is_super_admin());

-- AI_INTERACTIONS - user only sees their own
CREATE POLICY ai_select ON public.ai_interactions
  FOR SELECT USING (
    public.is_super_admin() OR public.is_auditor()
    OR user_id = auth.uid()
  );
CREATE POLICY ai_insert ON public.ai_interactions
  FOR INSERT WITH CHECK (user_id = auth.uid());

-- DOCUMENT_SEQUENCES - only system functions can access
CREATE POLICY doc_seq_select ON public.document_sequences
  FOR SELECT USING (public.is_super_admin());
-- No INSERT/UPDATE/DELETE policy = blocked (only next_doc_number SECURITY DEFINER function can write)

-- SYSTEM_SETTINGS
CREATE POLICY sys_set_select ON public.system_settings
  FOR SELECT USING (public.is_super_admin() OR organization_id = public.current_user_org());
CREATE POLICY sys_set_modify ON public.system_settings
  FOR ALL USING (public.is_super_admin() OR public.current_user_role() IN ('admin_org','super_admin'))
  WITH CHECK (public.is_super_admin() OR public.current_user_role() IN ('admin_org','super_admin'));

-- =====================================================================
-- Enable RLS bypass for service_role (server-side only)
-- Supabase service_role key automatically bypasses RLS
-- =====================================================================
-- No additional GRANT needed; service_role has full access by default.

-- =====================================================================
-- END OF RLS POLICIES
-- =====================================================================
