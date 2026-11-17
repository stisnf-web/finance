// =====================================================================
// Edge Function: post-journal
// Endpoint: POST /functions/v1/post-journal
// =====================================================================
// Memposting jurnal double-entry secara atomik dengan validasi:
//   1. Total Debit = Total Kredit
//   2. Periode akuntansi tidak ditutup
//   3. Akun COA valid & aktif
//   4. Generate journal number atomically (anti-duplikasi)
//   5. Update cash_bank balance jika transaksi cash/bank
//
// Menggunakan PostgreSQL function post_journal() yang sudah didefinisikan
// di schema.sql (SECURITY DEFINER).
// =====================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

interface JournalDetail {
  account_code: string;
  description?: string;
  debit: number;
  credit: number;
}

interface RequestBody {
  date: string; // YYYY-MM-DD
  type: string;
  description: string;
  details: JournalDetail[];
  ref_type?: string;
  ref_id?: string;
  ref_no?: string;
  department_id?: string;
  update_cash_balance?: boolean; // optional auto-update cash/bank balance
  cash_bank_id?: string;
  cash_bank_amount?: number; // positive = increase, negative = decrease
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

    // Use service_role for atomic operations (server-side only!)
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, serviceKey);

    // Also verify user via anon client
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
      .select("id, organization_id, name, role")
      .eq("id", user.id)
      .single();

    if (!profile) {
      return new Response(JSON.stringify({ error: "Profile not found" }), {
        status: 403,
        headers: { "Content-Type": "application/json" },
      });
    }

    // RBAC: only accounting/finance/admin roles can post journal
    const allowedRoles = ["staf_akuntansi", "manager_finance", "admin_org", "super_admin", "bendahara"];
    if (!allowedRoles.includes(profile.role)) {
      return new Response(
        JSON.stringify({ error: "Forbidden: role tidak diizinkan posting jurnal" }),
        { status: 403, headers: { "Content-Type": "application/json" } }
      );
    }

    const body: RequestBody = await req.json();

    // Validate input
    if (!body.date || !body.type || !body.description || !body.details || body.details.length < 2) {
      return new Response(JSON.stringify({ error: "Data input tidak lengkap (min 2 detail lines)" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    const totalDebit = body.details.reduce((s, d) => s + Number(d.debit), 0);
    const totalCredit = body.details.reduce((s, d) => s + Number(d.credit), 0);

    if (Math.abs(totalDebit - totalCredit) >= 0.01) {
      return new Response(
        JSON.stringify({
          error: `Jurnal tidak seimbang: Debit ${totalDebit} != Kredit ${totalCredit}`,
          total_debit: totalDebit,
          total_credit: totalCredit,
        }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    if (totalDebit === 0) {
      return new Response(JSON.stringify({ error: "Jurnal tidak boleh kosong (total = 0)" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Validate period not closed
    const period = body.date.slice(0, 7);
    const { data: closing } = await supabase
      .from("accounting_period_closings")
      .select("id")
      .eq("organization_id", profile.organization_id)
      .eq("period", period)
      .maybeSingle();

    if (closing) {
      return new Response(
        JSON.stringify({ error: `Periode ${period} sudah ditutup, transaksi tidak dapat diposting` }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Call atomic PostgreSQL function
    const { data: journalId, error: fnError } = await supabase.rpc("post_journal", {
      p_org: profile.organization_id,
      p_user: profile.id,
      p_date: body.date,
      p_type: body.type,
      p_desc: body.description,
      p_details: body.details,
      p_ref_type: body.ref_type || null,
      p_ref_id: body.ref_id || null,
      p_ref_no: body.ref_no || null,
      p_dept: body.department_id || null,
    });

    if (fnError) {
      console.error("post_journal error:", fnError);
      return new Response(
        JSON.stringify({ error: "Posting jurnal gagal", detail: fnError.message }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    // Optional: update cash_bank balance if requested
    if (body.update_cash_balance && body.cash_bank_id && body.cash_bank_amount) {
      const { error: cbError } = await supabase.rpc("update_cash_bank_balance", {
        p_id: body.cash_bank_id,
        p_delta: body.cash_bank_amount,
      });
      if (cbError) {
        console.warn("Failed to update cash_bank balance:", cbError.message);
        // Journal still posted - log warning
      }
    }

    // Get the journal entry for response
    const { data: journal } = await supabase
      .from("journal_entries")
      .select("journal_no, total_debit, total_credit, posted_at")
      .eq("id", journalId)
      .single();

    return new Response(
      JSON.stringify({
        success: true,
        journal_id: journalId,
        journal_no: journal?.journal_no,
        total_debit: journal?.total_debit,
        total_credit: journal?.total_credit,
        posted_at: journal?.posted_at,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("post-journal error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error", detail: String(err) }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
