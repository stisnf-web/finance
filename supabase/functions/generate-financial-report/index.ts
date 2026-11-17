// =====================================================================
// Edge Function: generate-financial-report
// Endpoint: POST /functions/v1/generate-financial-report
// =====================================================================
// Menghasilkan laporan keuangan (Neraca, Laba Rugi, Arus Kas,
// Perubahan Ekuitas, Neraca Saldo, Buku Besar) berdasarkan
// jurnal yang telah diposting.
//
// Output: JSON structured data (frontend akan render ke PDF/Excel)
// =====================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

interface RequestBody {
  report_type: "balance_sheet" | "income_statement" | "cash_flow" | "equity_changes" | "trial_balance" | "general_ledger";
  start_date?: string;
  end_date?: string;
  department_id?: string;
  account_code?: string;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 200,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  try {
    const authHeader = req.headers.get("Authorization") || "";
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: { user }, error: authError } = await userClient.auth.getUser();
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    const { data: profile } = await userClient
      .from("profiles")
      .select("organization_id, role")
      .eq("id", user.id)
      .single();

    if (!profile) {
      return new Response(JSON.stringify({ error: "Profile not found" }), {
        status: 403,
        headers: { "Content-Type": "application/json" },
      });
    }

    const body: RequestBody = await req.json();
    const supabase = createClient(supabaseUrl, serviceKey);
    const orgId = profile.organization_id;

    // Refresh materialized view first
    await supabase.rpc("refresh_account_balances");

    // Get all COA for this org
    const { data: coa } = await supabase
      .from("chart_of_accounts")
      .select("id, code, name, type, subtype, parent_id, level, is_group, active")
      .eq("organization_id", orgId)
      .order("code");

    // Get all balances from materialized view
    const { data: balances } = await supabase
      .from("mv_account_balances")
      .select("account_code, total_debit, total_credit, net_balance")
      .eq("organization_id", orgId);

    const balanceMap: Record<string, { debit: number; credit: number; net: number }> = {};
    (balances || []).forEach((b: any) => {
      balanceMap[b.account_code] = {
        debit: Number(b.total_debit),
        credit: Number(b.total_credit),
        net: Number(b.net_balance),
      };
    });

    // Get organization info
    const { data: org } = await supabase
      .from("organizations")
      .select("name, fiscal_year, currency")
      .eq("id", orgId)
      .single();

    const response: any = {
      organization: org,
      generated_at: new Date().toISOString(),
      report_type: body.report_type,
      period: { start_date: body.start_date, end_date: body.end_date },
    };

    if (body.report_type === "trial_balance") {
      const rows = (coa || [])
        .filter((a: any) => balanceMap[a.code] && (balanceMap[a.code].debit > 0 || balanceMap[a.code].credit > 0))
        .map((a: any) => ({
          code: a.code,
          name: a.name,
          type: a.type,
          debit: balanceMap[a.code].debit,
          credit: balanceMap[a.code].credit,
        }));
      const totalDebit = rows.reduce((s: number, r: any) => s + r.debit, 0);
      const totalCredit = rows.reduce((s: number, r: any) => s + r.credit, 0);
      response.rows = rows;
      response.total_debit = totalDebit;
      response.total_credit = totalCredit;
      response.is_balanced = Math.abs(totalDebit - totalCredit) < 0.01;
    }
    else if (body.report_type === "balance_sheet") {
      const assets = (coa || []).filter((a: any) => a.type === "asset" && a.level === 1);
      const liabilities = (coa || []).filter((a: any) => a.type === "liabilitas" && a.level === 1);
      const equity = (coa || []).filter((a: any) => a.type === "ekuitas" && a.level === 1);
      const totalAssets = assets.reduce((s: number, a: any) => s + (balanceMap[a.code]?.net || 0), 0);
      const totalLiab = liabilities.reduce((s: number, a: any) => s + (balanceMap[a.code]?.net || 0), 0);
      // For liabilities/equity, net is typically negative (credit normal), so flip sign
      const totalLiabAbs = Math.abs(totalLiab);
      const totalEquityAbs = Math.abs(equity.reduce((s: number, a: any) => s + (balanceMap[a.code]?.net || 0), 0));
      // Income - Expense = surplus
      const income = (coa || []).filter((a: any) => a.type === "pendapatan").reduce((s: number, a: any) => s + (balanceMap[a.code]?.net || 0), 0);
      const expense = (coa || []).filter((a: any) => a.type === "beban").reduce((s: number, a: any) => s + (balanceMap[a.code]?.net || 0), 0);
      const surplus = Math.abs(income) - Math.abs(expense);

      response.assets = assets.map((a: any) => ({ code: a.code, name: a.name, balance: balanceMap[a.code]?.net || 0 }));
      response.liabilities = liabilities.map((a: any) => ({ code: a.code, name: a.name, balance: Math.abs(balanceMap[a.code]?.net || 0) }));
      response.equity = equity.map((a: any) => ({ code: a.code, name: a.name, balance: Math.abs(balanceMap[a.code]?.net || 0) }));
      response.surplus = surplus;
      response.total_assets = totalAssets;
      response.total_liabilities = totalLiabAbs;
      response.total_equity = totalEquityAbs + surplus;
      response.is_balanced = Math.abs(totalAssets - (totalLiabAbs + totalEquityAbs + surplus)) < 0.01;
    }
    else if (body.report_type === "income_statement") {
      const incomes = (coa || []).filter((a: any) => a.type === "pendapatan" && a.level === 1);
      const expenses = (coa || []).filter((a: any) => a.type === "beban" && a.level === 1);
      const totalIncome = incomes.reduce((s: number, a: any) => s + Math.abs(balanceMap[a.code]?.net || 0), 0);
      const totalExpense = expenses.reduce((s: number, a: any) => s + Math.abs(balanceMap[a.code]?.net || 0), 0);
      response.incomes = incomes.map((a: any) => ({ code: a.code, name: a.name, balance: Math.abs(balanceMap[a.code]?.net || 0) }));
      response.expenses = expenses.map((a: any) => ({ code: a.code, name: a.name, balance: Math.abs(balanceMap[a.code]?.net || 0) }));
      response.total_income = totalIncome;
      response.total_expense = totalExpense;
      response.surplus = totalIncome - totalExpense;
    }
    else if (body.report_type === "cash_flow") {
      // Get income/expense transactions affecting cash/bank
      const { data: incomes } = await supabase
        .from("income_transactions")
        .select("amount, status, method, date")
        .eq("organization_id", orgId)
        .eq("status", "posted");
      const { data: expenses } = await supabase
        .from("expense_requests")
        .select("amount, status, method, date")
        .eq("organization_id", orgId)
        .eq("status", "paid");

      const totalIn = (incomes || []).reduce((s: number, t: any) => s + Number(t.amount), 0);
      const totalOut = (expenses || []).reduce((s: number, t: any) => s + Number(t.amount), 0);

      const { data: cb } = await supabase
        .from("cash_bank_accounts")
        .select("name, opening_balance, balance")
        .eq("organization_id", orgId)
        .eq("active", true);

      response.operating_inflow = totalIn;
      response.operating_outflow = totalOut;
      response.net_operating = totalIn - totalOut;
      response.opening_cash = (cb || []).reduce((s: number, c: any) => s + Number(c.opening_balance), 0);
      response.ending_cash = (cb || []).reduce((s: number, c: any) => s + Number(c.balance), 0);
    }
    else if (body.report_type === "equity_changes") {
      const openingEquity = balanceMap["3200"]?.net || 0;
      const income = (coa || []).filter((a: any) => a.type === "pendapatan").reduce((s: number, a: any) => s + Math.abs(balanceMap[a.code]?.net || 0), 0);
      const expense = (coa || []).filter((a: any) => a.type === "beban").reduce((s: number, a: any) => s + Math.abs(balanceMap[a.code]?.net || 0), 0);
      const surplus = income - expense;
      const donations = Math.abs(balanceMap["4300"]?.net || 0);
      response.opening_equity = openingEquity;
      response.surplus = surplus;
      response.donations_unrestricted = donations;
      response.ending_equity = openingEquity + surplus + donations;
    }
    else if (body.report_type === "general_ledger") {
      const targetAccount = body.account_code;
      if (!targetAccount) {
        return new Response(JSON.stringify({ error: "account_code required for general_ledger" }), {
          status: 400,
          headers: { "Content-Type": "application/json" },
        });
      }
      // Get journal details for this account
      const { data: journals } = await supabase
        .from("journal_entries")
        .select(`
          id, journal_no, date, description, status,
          journal_details!inner(account_code, description, debit, credit)
        `)
        .eq("organization_id", orgId)
        .eq("status", "posted")
        .eq("journal_details.account_code", targetAccount)
        .order("date", { ascending: true });

      const acc = (coa || []).find((a: any) => a.code === targetAccount);
      const postings: any[] = [];
      let runningBalance = 0;
      const isDebitNormal = acc?.type === "asset" || acc?.type === "beban";

      (journals || []).forEach((j: any) => {
        j.journal_details.forEach((d: any) => {
          if (d.account_code === targetAccount) {
            runningBalance += (Number(d.debit) - Number(d.credit)) * (isDebitNormal ? 1 : -1);
            postings.push({
              date: j.date,
              journal_no: j.journal_no,
              description: d.description || j.description,
              debit: Number(d.debit),
              credit: Number(d.credit),
              balance: runningBalance,
            });
          }
        });
      });

      response.account = acc;
      response.postings = postings;
      response.ending_balance = runningBalance;
    }

    // Log audit
    await supabase.from("audit_logs").insert({
      organization_id: orgId,
      user_id: user.id,
      user_name: profile.role,
      action: "Generate Report",
      description: `Generate ${body.report_type} report`,
      ref_type: "report",
      ref_no: body.report_type,
    });

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (err) {
    console.error("generate-financial-report error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error", detail: String(err) }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
