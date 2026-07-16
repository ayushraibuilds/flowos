// FlowOS Options — account auth, site categorization, data management.

function getAccountConfig() {
  const config = globalThis.FLOWOS_CONFIG || {};
  return {
    supabaseUrl: config.supabaseUrl || '',
    supabasePublishableKey: config.supabasePublishableKey || '',
  };
}

function isAccountSyncConfigured() {
  const { supabaseUrl, supabasePublishableKey } = getAccountConfig();
  return Boolean(supabaseUrl && supabasePublishableKey);
}

document.addEventListener('DOMContentLoaded', async () => {
  await loadSettings();
  setupListeners();
});

async function loadSettings() {
  const { email, accessToken, customCategories = {} } = await chrome.storage.local.get([
    'email', 'accessToken', 'customCategories',
  ]);

  // Legacy manual url/key removal is disabled to prevent wiping paired connection settings.

  document.getElementById('email').value = email || '';
  const loginButton = document.getElementById('loginBtn');
  const statusEl = document.getElementById('authStatus');

  if (!isAccountSyncConfigured()) {
    loginButton.disabled = true;
    loginButton.title = 'Account sync is not configured in this build.';
    statusEl.textContent = 'Account sync is unavailable in this build. Browsing insights remain local.';
    statusEl.className = 'status';
  } else if (accessToken) {
    statusEl.textContent = '✅ Signed in';
    statusEl.className = 'status success';
    loginButton.textContent = 'Update';
  }

  const { isPaired = false } = await chrome.storage.local.get('isPaired');
  const pairingStatus = document.getElementById('pairingStatus');
  if (isPaired) {
    pairingStatus.textContent = '✅ Paired with FlowOS App';
    pairingStatus.className = 'status success';
    document.getElementById('pairBtn').textContent = 'Update Pairing';
  }

  renderCategories(customCategories);
}

function renderCategories(categories) {
  const container = document.getElementById('categoryList');
  const entries = Object.entries(categories);
  container.replaceChildren();

  if (entries.length === 0) {
    const emptyState = document.createElement('div');
    emptyState.style.cssText = 'color: #4A5568; font-size: 12px;';
    emptyState.textContent = 'No custom categories yet';
    container.append(emptyState);
    return;
  }

  entries.forEach(([domain, category]) => {
    const row = document.createElement('div');
    row.className = 'category-item';

    const domainLabel = document.createElement('span');
    domainLabel.className = 'category-domain';
    domainLabel.textContent = domain;

    const select = document.createElement('select');
    ['productive', 'neutral', 'distracting'].forEach((value) => {
      const option = document.createElement('option');
      option.value = value;
      option.textContent = value[0].toUpperCase() + value.slice(1);
      option.selected = category === value;
      select.append(option);
    });
    select.addEventListener('change', async (e) => {
      await chrome.runtime.sendMessage({
        type: 'CATEGORIZE_SITE',
        domain,
        category: e.target.value,
      });
    });

    const removeButton = document.createElement('button');
    removeButton.className = 'remove-btn';
    removeButton.type = 'button';
    removeButton.textContent = '✕';
    removeButton.addEventListener('click', async () => {
      const { customCategories = {} } = await chrome.storage.local.get('customCategories');
      delete customCategories[domain];
      await chrome.storage.local.set({ customCategories });
      renderCategories(customCategories);
    });

    row.append(domainLabel, select, removeButton);
    container.append(row);
  });
}

function setupListeners() {
  // Login
  document.getElementById('loginBtn').addEventListener('click', async () => {
    const { supabaseUrl, supabasePublishableKey } = getAccountConfig();
    const email = document.getElementById('email').value.trim();
    const password = document.getElementById('password').value;
    const statusEl = document.getElementById('authStatus');

    if (!isAccountSyncConfigured()) {
      statusEl.textContent = '❌ Account sync is not configured in this build.';
      statusEl.className = 'status error';
      return;
    }

    if (!email || !password) {
      statusEl.textContent = '❌ Email and password are required';
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
          'apikey': supabasePublishableKey,
        },
        body: JSON.stringify({ email, password }),
      });

      if (res.ok) {
        const data = await res.json();
        if (!data.user?.id) {
          throw new Error('The account response did not include a user identity.');
        }

        await chrome.storage.local.set({
          email,
          accessToken: data.access_token,
          refreshToken: data.refresh_token,
          tokenExpiresAt: Date.now() + ((data.expires_in || 0) * 1000),
          userId: data.user.id,
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

  // Pair mobile app
  document.getElementById('pairBtn').addEventListener('click', async () => {
    const token = document.getElementById('pairingToken').value.trim();
    const statusEl = document.getElementById('pairingStatus');
    if (!token) {
      statusEl.textContent = '❌ Please enter a pairing token';
      statusEl.className = 'status error';
      return;
    }
    statusEl.textContent = 'Pairing...';
    statusEl.className = 'status';
    try {
      const decoded = atob(token);
      const data = JSON.parse(decoded);
      if (!data.userId || !data.supabaseUrl || !data.supabaseKey) {
        throw new Error('Invalid pairing token format');
      }
      await chrome.storage.local.set({
        userId: data.userId,
        supabaseUrl: data.supabaseUrl,
        supabasePublishableKey: data.supabaseKey,
        isPaired: true,
      });
      statusEl.textContent = '✅ Paired successfully!';
      statusEl.className = 'status success';
      document.getElementById('pairBtn').textContent = 'Update Pairing';
      document.getElementById('pairingToken').value = '';
      
      // Request active session sync immediately
      await chrome.runtime.sendMessage({ type: 'SYNC_FOCUS_STATE' });
    } catch (err) {
      statusEl.textContent = `❌ Pairing failed: ${err.message}`;
      statusEl.className = 'status error';
    }
  });
}
