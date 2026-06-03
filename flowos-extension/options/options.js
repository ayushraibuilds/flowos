// FlowOS Options — Supabase auth, site categorization, data management.

document.addEventListener('DOMContentLoaded', async () => {
  await loadSettings();
  setupListeners();
});

async function loadSettings() {
  const { supabaseUrl, supabaseKey, email, accessToken, customCategories = {} } =
    await chrome.storage.local.get([
      'supabaseUrl', 'supabaseKey', 'email', 'accessToken', 'customCategories',
    ]);

  document.getElementById('supabaseUrl').value = supabaseUrl || '';
  document.getElementById('supabaseKey').value = supabaseKey || '';
  document.getElementById('email').value = email || '';

  if (accessToken) {
    document.getElementById('authStatus').textContent = '✅ Signed in';
    document.getElementById('authStatus').className = 'status success';
    document.getElementById('loginBtn').textContent = 'Update';
  }

  renderCategories(customCategories);
}

function renderCategories(categories) {
  const container = document.getElementById('categoryList');
  const entries = Object.entries(categories);

  if (entries.length === 0) {
    container.innerHTML = '<div style="color: #4A5568; font-size: 12px;">No custom categories yet</div>';
    return;
  }

  container.innerHTML = entries.map(([domain, category]) => `
    <div class="category-item" data-domain="${domain}">
      <span class="category-domain">${domain}</span>
      <select class="category-select" data-domain="${domain}">
        <option value="productive" ${category === 'productive' ? 'selected' : ''}>Productive</option>
        <option value="neutral" ${category === 'neutral' ? 'selected' : ''}>Neutral</option>
        <option value="distracting" ${category === 'distracting' ? 'selected' : ''}>Distracting</option>
      </select>
      <button class="remove-btn" data-domain="${domain}">✕</button>
    </div>
  `).join('');

  // Change listeners
  container.querySelectorAll('.category-select').forEach(select => {
    select.addEventListener('change', async (e) => {
      const domain = e.target.dataset.domain;
      await chrome.runtime.sendMessage({
        type: 'CATEGORIZE_SITE',
        domain,
        category: e.target.value,
      });
    });
  });

  // Remove listeners
  container.querySelectorAll('.remove-btn').forEach(btn => {
    btn.addEventListener('click', async (e) => {
      const domain = e.target.dataset.domain;
      const { customCategories = {} } = await chrome.storage.local.get('customCategories');
      delete customCategories[domain];
      await chrome.storage.local.set({ customCategories });
      renderCategories(customCategories);
    });
  });
}

function setupListeners() {
  // Login
  document.getElementById('loginBtn').addEventListener('click', async () => {
    const supabaseUrl = document.getElementById('supabaseUrl').value.trim();
    const supabaseKey = document.getElementById('supabaseKey').value.trim();
    const email = document.getElementById('email').value.trim();
    const password = document.getElementById('password').value;
    const statusEl = document.getElementById('authStatus');

    if (!supabaseUrl || !supabaseKey || !email || !password) {
      statusEl.textContent = '❌ All fields required';
      statusEl.className = 'status error';
      return;
    }

    statusEl.textContent = 'Signing in...';
    statusEl.className = 'status';

    try {
      const res = await fetch(`${supabaseUrl}/auth/v1/token?grant_type=password`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'apikey': supabaseKey,
        },
        body: JSON.stringify({ email, password }),
      });

      if (res.ok) {
        const data = await res.json();
        await chrome.storage.local.set({
          supabaseUrl,
          supabaseKey,
          email,
          accessToken: data.access_token,
          refreshToken: data.refresh_token,
        });
        statusEl.textContent = '✅ Signed in successfully!';
        statusEl.className = 'status success';
      } else {
        const err = await res.json();
        statusEl.textContent = `❌ ${err.error_description || err.msg || 'Auth failed'}`;
        statusEl.className = 'status error';
      }
    } catch (err) {
      statusEl.textContent = `❌ Connection error: ${err.message}`;
      statusEl.className = 'status error';
    }
  });

  // Add category
  document.getElementById('addCategoryBtn').addEventListener('click', async () => {
    const domain = document.getElementById('newDomain').value.trim().replace('www.', '');
    const category = document.getElementById('newCategory').value;

    if (!domain) return;

    await chrome.runtime.sendMessage({
      type: 'CATEGORIZE_SITE',
      domain,
      category,
    });

    document.getElementById('newDomain').value = '';
    const { customCategories = {} } = await chrome.storage.local.get('customCategories');
    renderCategories(customCategories);
  });

  // Clear data
  document.getElementById('clearDataBtn').addEventListener('click', async () => {
    if (!confirm('This will delete all browsing data. Continue?')) return;

    await chrome.storage.local.set({
      visits: [],
      flowScore: 0,
      todayStats: { productive: 0, neutral: 0, distracting: 0 },
      syncQueue: [],
      lastSyncTime: 0,
    });

    document.getElementById('clearStatus').textContent = '✅ Data cleared';
    document.getElementById('clearStatus').className = 'status success';
  });
}
