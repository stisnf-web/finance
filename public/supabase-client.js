/* =====================================================================
   FINANCE PRO - Supabase Client Integration Layer
   =====================================================================
   File ini menyediakan wrapper untuk Supabase client.
   Aktifkan dengan set: USE_SUPABASE = true (di finance-pro.html)

   Penggunaan:
   1. Tambahkan script tag SEBELUM script utama di finance-pro.html:
      <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
      <script src="supabase-client.js"></script>

   2. Set konfigurasi:
      <script>
        window.FINANCE_PRO_CONFIG = {
          SUPABASE_URL: 'https://your-project.supabase.co',
          SUPABASE_ANON_KEY: 'your-anon-key',
          USE_SUPABASE: true  // false = demo mode (localStorage)
        };
      </script>

   3. Ganti panggilan loadDB/saveDB/doLogin untuk menggunakan wrapper ini
   ===================================================================== */

window.FinanceProSupabase = (function() {
  let client = null;
  let config = window.FINANCE_PRO_CONFIG || {
    SUPABASE_URL: '',
    SUPABASE_ANON_KEY: '',
    USE_SUPABASE: false
  };

  // Initialize client
  function init() {
    if (!config.USE_SUPABASE || !config.SUPABASE_URL || !config.SUPABASE_ANON_KEY) {
      console.warn('[FinancePro] Supabase not configured, using demo mode (localStorage)');
      return null;
    }
    if (!window.supabase) {
      console.error('[FinancePro] Supabase JS SDK not loaded. Add: <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>');
      return null;
    }
    client = window.supabase.createClient(config.SUPABASE_URL, config.SUPABASE_ANON_KEY, {
      auth: { persistSession: true, autoRefreshToken: true }
    });
    console.log('[FinancePro] Supabase client initialized');
    return client;
  }

  function getClient() { return client; }
  function isProduction() { return !!client; }

  // ============== AUTH ==============
  async function login(email, password) {
    if (!client) throw new Error('Supabase not initialized');
    const { data, error } = await client.auth.signInWithPassword({ email, password });
    if (error) throw error;
    // Load profile
    const { data: profile, error: pErr } = await client
      .from('profiles')
      .select('*, departments(name)')
      .eq('id', data.user.id)
      .single();
    if (pErr) throw pErr;
    return { user: data.user, profile, session: data.session };
  }

  async function logout() {
    if (!client) return;
    await client.auth.signOut();
  }

  async function getCurrentSession() {
    if (!client) return null;
    const { data } = await client.auth.getSession();
    return data.session;
  }

  async function getCurrentProfile() {
    if (!client) return null;
    const { data: { user } } = await client.auth.getUser();
    if (!user) return null;
    const { data: profile } = await client.from('profiles')
      .select('*').eq('id', user.id).single();
    return profile;
  }

  // ============== GENERIC CRUD ==============
  async function selectAll(table, filters = {}) {
    if (!client) throw new Error('Supabase not initialized');
    let query = client.from(table).select('*');
    Object.entries(filters).forEach(([k, v]) => {
      if (v !== undefined && v !== null && v !== '') {
        query = query.eq(k, v);
      }
    });
    const { data, error } = await query.order('created_at', { ascending: false });
    if (error) throw error;
    return data || [];
  }

  async function selectById(table, id) {
    if (!client) throw new Error('Supabase not initialized');
    const { data, error } = await client.from(table).select('*').eq('id', id).single();
    if (error) throw error;
    return data;
  }

  async function insert(table, record) {
    if (!client) throw new Error('Supabase not initialized');
    const { data, error } = await client.from(table).insert(record).select().single();
    if (error) throw error;
    return data;
  }

  async function update(table, id, updates) {
    if (!client) throw new Error('Supabase not initialized');
    const { data, error } = await client.from(table).update(updates).eq('id', id).select().single();
    if (error) throw error;
    return data;
  }

  async function remove(table, id) {
    if (!client) throw new Error('Supabase not initialized');
    const { error } = await client.from(table).delete().eq('id', id);
    if (error) throw error;
    return true;
  }

  // ============== EDGE FUNCTION CALLS ==============
  async function callFunction(name, body) {
    if (!client) throw new Error('Supabase not initialized');
    const { data: { session } } = await client.auth.getSession();
    if (!session) throw new Error('No active session');

    const url = `${config.SUPABASE_URL}/functions/v1/${name}`;
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${session.access_token}`,
        'Content-Type': 'application/json',
        'apikey': config.SUPABASE_ANON_KEY
      },
      body: JSON.stringify(body)
    });
    if (!response.ok) {
      const err = await response.json();
      throw new Error(err.error || `Function ${name} failed: ${response.status}`);
    }
    return await response.json();
  }

  async function askAI(question, history = []) {
    return callFunction('ai-assistant', { question, history });
  }

  async function postJournal(journalData) {
    return callFunction('post-journal', journalData);
  }

  async function generateDocNo(docType, year = null) {
    return callFunction('generate-doc-no', { doc_type: docType, year });
  }

  async function generateReport(reportType, params = {}) {
    return callFunction('generate-financial-report', { report_type: reportType, ...params });
  }

  // ============== FINANCE-SPECIFIC ==============
  async function loadAllData(organization_id) {
    if (!client) return null;
    const tables = [
      'organizations', 'departments', 'chart_of_accounts',
      'cash_bank_accounts', 'budget_plans',
      'income_transactions', 'expense_requests', 'fund_transfers',
      'receivables', 'payables', 'fixed_assets',
      'tax_types', 'tax_transactions',
      'notifications'
    ];
    const results = {};
    for (const t of tables) {
      try {
        let q = client.from(t).select('*');
        // organization_id filter (RLS will enforce, but optimize query)
        if (t !== 'organizations' && organization_id) {
          q = q.eq('organization_id', organization_id);
        }
        const { data, error } = await q.order('created_at', { ascending: false });
        if (error) console.warn(`[${t}] load error:`, error.message);
        results[t] = data || [];
      } catch (e) {
        console.warn(`[${t}] exception:`, e);
        results[t] = [];
      }
    }
    // Special: journal_entries with details
    try {
      const { data: jv } = await client.from('journal_entries')
        .select('*, journal_details(*)')
        .eq('organization_id', organization_id)
        .order('date', { ascending: false });
      results.journal_entries = jv || [];
    } catch (e) {
      results.journal_entries = [];
    }
    // Audit logs (limited)
    try {
      const { data: aud } = await client.from('audit_logs')
        .select('*').eq('organization_id', organization_id)
        .order('created_at', { ascending: false }).limit(200);
      results.audit_logs = aud || [];
    } catch (e) {
      results.audit_logs = [];
    }
    return results;
  }

  // ============== STORAGE (file upload) ==============
  async function uploadFile(bucket, path, file) {
    if (!client) throw new Error('Supabase not initialized');
    const { data, error } = await client.storage.from(bucket).upload(path, file, {
      cacheControl: '3600',
      upsert: false
    });
    if (error) throw error;
    const { data: urlData } = client.storage.from(bucket).getPublicUrl(path);
    return urlData.publicUrl;
  }

  async function getSignedUrl(bucket, path, expiresIn = 3600) {
    if (!client) throw new Error('Supabase not initialized');
    const { data, error } = await client.storage.from(bucket).createSignedUrl(path, expiresIn);
    if (error) throw error;
    return data.signedUrl;
  }

  // ============== REALTIME SUBSCRIPTION ==============
  function subscribe(table, callback, filter = null) {
    if (!client) return null;
    let sub = client.channel(`realtime-${table}-${Date.now()}`)
      .on('postgres_changes',
        { event: '*', schema: 'public', table, filter: filter || undefined },
        (payload) => callback(payload)
      )
      .subscribe();
    return sub;
  }

  function unsubscribe(sub) {
    if (client && sub) {
      client.removeChannel(sub);
    }
  }

  // ============== PUBLIC API ==============
  return {
    init,
    getClient,
    isProduction,
    config,
    // Auth
    login, logout, getCurrentSession, getCurrentProfile,
    // CRUD
    selectAll, selectById, insert, update, remove,
    // Edge Functions
    callFunction, askAI, postJournal, generateDocNo, generateReport,
    // Finance-specific
    loadAllData,
    // Storage
    uploadFile, getSignedUrl,
    // Realtime
    subscribe, unsubscribe
  };
})();
