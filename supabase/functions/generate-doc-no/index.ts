// =====================================================================
// Edge Function: generate-doc-no
// Endpoint: POST /functions/v1/generate-doc-no
// =====================================================================
// Generate nomor dokumen atomik (anti-duplikasi pada concurrent insert).
// Tipe: income, expense, transfer, journal, budget
// =====================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

interface RequestBody {
  doc_type: "income" | "expense" | "transfer" | "journal" | "budget";
  year?: number;
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

    // Verify user
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
      .select("organization_id")
      .eq("id", user.id)
      .single();

    if (!profile) {
      return new Response(JSON.stringify({ error: "Profile not found" }), {
        status: 403,
        headers: { "Content-Type": "application/json" },
      });
    }

    const body: RequestBody = await req.json();
    if (!body.doc_type) {
      return new Response(JSON.stringify({ error: "doc_type required" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Use service role to call atomic function
    const supabase = createClient(supabaseUrl, serviceKey);
    const { data: docNo, error } = await supabase.rpc("next_doc_number", {
      p_org: profile.organization_id,
      p_type: body.doc_type,
      p_year: body.year || null,
    });

    if (error) {
      return new Response(
        JSON.stringify({ error: "Failed to generate doc number", detail: error.message }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ doc_no: docNo }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("generate-doc-no error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error", detail: String(err) }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
