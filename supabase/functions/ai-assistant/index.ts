// =====================================================================
// Edge Function: ai-assistant
// Endpoint: POST /functions/v1/ai-assistant
// =====================================================================
// Memproses pertanyaan keuangan dari user dan mengembalikan jawaban AI.
// AI hanya memberikan analisis & rekomendasi - TIDAK melakukan aksi
// finansial (no posting jurnal, no approval, no payment).
//
// Menggunakan Gemini API atau OpenAI (fallback) berdasarkan env.
// API key disimpan di server-side (Supabase Edge Function secret),
// JANGAN pernah menaruh API key di frontend.
// =====================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SYSTEM_PROMPT = `Anda adalah AI Financial Assistant untuk aplikasi FINANCE PRO.
Peran Anda:
- Meringkas laporan keuangan
- Menganalisis realisasi anggaran
- Menemukan unit dengan deviasi anggaran
- Membantu proyeksi pengeluaran
- Menganalisis tren kas dan bank
- Menyusun narasi laporan keuangan
- Memberikan rekomendasi efisiensi biaya
- Membantu klasifikasi transaksi berdasarkan COA

ATURAN KEAMANAN (WAJIB DIPATUHI):
- Anda TIDAK BOLEH mengesahkan transaksi
- Anda TIDAK BOLEH memposting jurnal
- Anda TIDAK BOLEH mengubah anggaran
- Anda TIDAK BOLEH melakukan pembayaran
- Anda HANYA memberikan analisis dan rekomendasi

Format jawaban:
- Gunakan Bahasa Indonesia
- Singkat padat dan jelas
- Gunakan format mata uang Rp (Indonesia)
- Sertakan angka konkret bila ada
- Jika tidak yakin, katakan "Saya tidak yakin" - jangan mengarang angka`;

interface ChatMessage {
  role: 'system' | 'user' | 'assistant';
  content: string;
}

interface RequestBody {
  question: string;
  context?: {
    organization_id?: string;
    page?: string;
    financial_summary?: Record<string, unknown>;
  };
  history?: ChatMessage[];
}

Deno.serve(async (req: Request) => {
  // Handle CORS preflight
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
    // Verify JWT
    const authHeader = req.headers.get("Authorization") || "";
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Get user profile
    const { data: profile } = await supabase
      .from("profiles")
      .select("id, organization_id, name, role, department_id")
      .eq("id", user.id)
      .single();

    if (!profile) {
      return new Response(JSON.stringify({ error: "Profile not found" }), {
        status: 403,
        headers: { "Content-Type": "application/json" },
      });
    }

    const body: RequestBody = await req.json();
    const question = body.question?.trim();
    if (!question) {
      return new Response(JSON.stringify({ error: "Question is required" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Build context payload based on question (RBAC-scoped)
    const financialContext = await buildFinancialContext(supabase, profile);

    // Construct messages
    const messages: ChatMessage[] = [
      { role: "system", content: SYSTEM_PROMPT },
      {
        role: "system",
        content: `KONTEKS KEUANGAN USER (organization_id: ${profile.organization_id}, role: ${profile.role}):\n${financialContext}`,
      },
      ...(body.history || []).slice(-10),
      { role: "user", content: question },
    ];

    // Call AI provider
    let answer: string;
    let model: string;
    let tokensUsed = 0;

    const geminiKey = Deno.env.get("GEMINI_API_KEY");
    const openaiKey = Deno.env.get("OPENAI_API_KEY");

    if (geminiKey) {
      const result = await callGemini(geminiKey, messages);
      answer = result.text;
      model = "gemini-pro";
      tokensUsed = result.tokens;
    } else if (openaiKey) {
      const result = await callOpenAI(openaiKey, messages);
      answer = result.text;
      model = "gpt-4o-mini";
      tokensUsed = result.tokens;
    } else {
      // Fallback: rule-based answer (so app still works without AI key)
      answer = generateFallbackAnswer(question, financialContext);
      model = "rule-based";
    }

    // Log interaction
    await supabase.from("ai_interactions").insert({
      organization_id: profile.organization_id,
      user_id: profile.id,
      question,
      answer,
      model,
      tokens_used: tokensUsed,
    });

    return new Response(
      JSON.stringify({ answer, model, tokens_used: tokensUsed }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("AI Assistant error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error", detail: String(err) }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});

// =====================================================================
// Build financial context (RBAC-scoped, read-only)
// =====================================================================
async function buildFinancialContext(supabase: any, profile: any): Promise<string> {
  const orgId = profile.organization_id;
  const lines: string[] = [];

  // Organization
  const { data: org } = await supabase
    .from("organizations")
    .select("name, fiscal_year, currency")
    .eq("id", orgId)
    .single();
  if (org) lines.push(`Organisasi: ${org.name}, Tahun buku: ${org.fiscal_year}, Mata uang: ${org.currency}`);

  // Budget summary
  const { data: budgets } = await supabase
    .from("budget_plans")
    .select("department_id, total, approved_amount, realization, status")
    .eq("organization_id", orgId)
    .eq("status", "approved");
  if (budgets && budgets.length) {
    const totalB = budgets.reduce((s: number, b: any) => s + Number(b.approved_amount), 0);
    const totalR = budgets.reduce((s: number, b: any) => s + Number(b.realization), 0);
    lines.push(`Total anggaran disetujui: Rp ${totalB.toLocaleString("id-ID")}`);
    lines.push(`Total realisasi: Rp ${totalR.toLocaleString("id-ID")} (${((totalR/totalB)*100).toFixed(1)}%)`);
    lines.push(`Sisa anggaran: Rp ${(totalB-totalR).toLocaleString("id-ID")}`);
  }

  // Income summary (current year)
  const { data: incomes } = await supabase
    .from("income_transactions")
    .select("amount, status, category")
    .eq("organization_id", orgId)
    .eq("status", "posted");
  if (incomes && incomes.length) {
    const total = incomes.reduce((s: number, t: any) => s + Number(t.amount), 0);
    lines.push(`Total pemasukan posted: Rp ${total.toLocaleString("id-ID")} dari ${incomes.length} transaksi`);
  }

  // Expense summary
  const { data: expenses } = await supabase
    .from("expense_requests")
    .select("amount, status, category")
    .eq("organization_id", orgId)
    .eq("status", "paid");
  if (expenses && expenses.length) {
    const total = expenses.reduce((s: number, t: any) => s + Number(t.amount), 0);
    lines.push(`Total pengeluaran paid: Rp ${total.toLocaleString("id-ID")} dari ${expenses.length} transaksi`);
  }

  // Cash & bank balances
  const { data: cb } = await supabase
    .from("cash_bank_accounts")
    .select("name, type, balance")
    .eq("organization_id", orgId)
    .eq("active", true);
  if (cb && cb.length) {
    const total = cb.reduce((s: number, c: any) => s + Number(c.balance), 0);
    lines.push(`Total saldo kas & bank: Rp ${total.toLocaleString("id-ID")}`);
    cb.forEach((c: any) => lines.push(`  - ${c.name} (${c.type}): Rp ${Number(c.balance).toLocaleString("id-ID")}`));
  }

  // Receivables & payables
  const { data: rcv } = await supabase
    .from("receivables")
    .select("amount, paid, status")
    .eq("organization_id", orgId);
  if (rcv && rcv.length) {
    const out = rcv.reduce((s: number, r: any) => s + (Number(r.amount) - Number(r.paid)), 0);
    lines.push(`Piutang outstanding: Rp ${out.toLocaleString("id-ID")}`);
  }
  const { data: pay } = await supabase
    .from("payables")
    .select("amount, paid, status")
    .eq("organization_id", orgId);
  if (pay && pay.length) {
    const out = pay.reduce((s: number, p: any) => s + (Number(p.amount) - Number(p.paid)), 0);
    lines.push(`Utang outstanding: Rp ${out.toLocaleString("id-ID")}`);
  }

  // Pending approvals
  const { count: pendingExp } = await supabase
    .from("expense_requests")
    .select("id", { count: "exact", head: true })
    .eq("organization_id", orgId)
    .in("status", ["submitted", "verified"]);
  if (pendingExp) lines.push(`Pengajuan pengeluaran menunggu approval: ${pendingExp}`);

  return lines.join("\n");
}

// =====================================================================
// Gemini API call
// =====================================================================
async function callGemini(apiKey: string, messages: ChatMessage[]): Promise<{ text: string; tokens: number }> {
  const contents = messages.map(m => ({
    role: m.role === "assistant" ? "model" : "user",
    parts: [{ text: m.content }],
  }));

  const res = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=${apiKey}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents,
        generationConfig: { temperature: 0.7, maxOutputTokens: 1500 },
        safetySettings: [
          { category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: "BLOCK_ONLY_HIGH" },
        ],
      }),
    }
  );

  if (!res.ok) {
    const errText = await res.text();
    throw new Error(`Gemini API error ${res.status}: ${errText}`);
  }

  const data = await res.json();
  const text = data.candidates?.[0]?.content?.parts?.[0]?.text || "Maaf, saya tidak dapat memberikan jawaban saat ini.";
  const tokens = data.usageMetadata?.totalTokenCount || 0;
  return { text, tokens };
}

// =====================================================================
// OpenAI API call (fallback)
// =====================================================================
async function callOpenAI(apiKey: string, messages: ChatMessage[]): Promise<{ text: string; tokens: number }> {
  const res = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: "gpt-4o-mini",
      messages,
      temperature: 0.7,
      max_tokens: 1500,
    }),
  });

  if (!res.ok) {
    const errText = await res.text();
    throw new Error(`OpenAI API error ${res.status}: ${errText}`);
  }

  const data = await res.json();
  const text = data.choices?.[0]?.message?.content || "Maaf, saya tidak dapat memberikan jawaban saat ini.";
  const tokens = data.usage?.total_tokens || 0;
  return { text, tokens };
}

// =====================================================================
// Fallback rule-based answer (jika tidak ada API key)
// =====================================================================
function generateFallbackAnswer(question: string, context: string): string {
  const q = question.toLowerCase();
  if (q.includes("realisasi") || q.includes("anggaran")) {
    const m = context.match(/Total anggaran disetujui: Rp ([\d.]+)/);
    const r = context.match(/Total realisasi: Rp ([\d.]+).*?(\d+\.?\d*)%/s);
    if (m) {
      return `📊 Berdasarkan data terkini:\nTotal anggaran disetujui: Rp ${m[1]}\n\nUntuk detail per unit, silakan buka menu Monitoring Realisasi. Saya juga bisa membantu menganalisis unit dengan deviasi tertinggi jika Anda tanyakan spesifik.`;
    }
  }
  if (q.includes("kas") || q.includes("bank")) {
    const m = context.match(/Total saldo kas & bank: Rp ([\d.]+)/);
    if (m) return `💰 Posisi kas & bank saat ini: Rp ${m[1]}\n\nDetail per rekening dapat dilihat di menu Kas & Bank.`;
  }
  return `🤖 Mode demo aktif - untuk mendapatkan jawaban AI cerdas, konfigurasikan GEMINI_API_KEY atau OPENAI_API_KEY di Supabase Edge Function secrets.\n\nKonteks keuangan terkini:\n${context}`;
}
