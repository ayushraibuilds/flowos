// FlowOS Service Worker — background tracking, sync, focus mode.
// Rule #7: NO global variable state. All state in chrome.storage.

// ─── Constants ──────────────────────────────────────────────────

const SYNC_INTERVAL_MINUTES = 5;
const BADGE_COLORS = {
  A: '#00D68F',
  B: '#4A9EFF',
  C: '#FFB74D',
  D: '#FF8A65',
  F: '#FF6B6B',
};

// ─── Install / Startup ─────────────────────────────────────────

chrome.runtime.onInstalled.addListener(async () => {
  // Set default storage
  const existing = await chrome.storage.local.get(['visits', 'flowScore', 'focusActive']);
  if (!existing.visits) {
    await chrome.storage.local.set({
      visits: [],
      flowScore: 0,
      focusActive: false,
      syncQueue: [],
      todayStats: { productive: 0, neutral: 0, distracting: 0 },
    });
  }

  // Set up sync alarm (every 5 minutes)
  await chrome.alarms.create('sync-to-supabase', {
    periodInMinutes: SYNC_INTERVAL_MINUTES,
  });

  // Set up Flow Score recalculation (every 1 minute)
  await chrome.alarms.create('recalc-flow-score', {
    periodInMinutes: 1,
  });

  console.log('FlowOS extension installed');
});

// ─── Tab Tracking ───────────────────────────────────────────────

chrome.tabs.onUpdated.addListener(async (tabId, changeInfo, tab) => {
  if (changeInfo.status !== 'complete' || !tab.url) return;

  // Skip browser internals
  if (tab.url.startsWith('chrome://') || tab.url.startsWith('chrome-extension://')) return;

  const url = new URL(tab.url);
  const domain = url.hostname.replace('www.', '');
  const timestamp = Date.now();

  // Get current visit tracking
  const { visits = [] } = await chrome.storage.local.get('visits');

  // Close previous visit for this tab
  const prevIndex = visits.findLastIndex(v => v.tabId === tabId && !v.endTime);
  if (prevIndex >= 0) {
    visits[prevIndex].endTime = timestamp;
    visits[prevIndex].duration = timestamp - visits[prevIndex].startTime;
  }

  // Start new visit
  const category = await categorize(domain);
  visits.push({
    tabId,
    domain,
    url: tab.url,
    title: tab.title || domain,
    category,
    startTime: timestamp,
    endTime: null,
    duration: 0,
  });

  // Keep last 500 visits max
  const trimmed = visits.slice(-500);
  await chrome.storage.local.set({ visits: trimmed });

  // Update today's stats
  await updateTodayStats();
});

// Close visit when tab closes
chrome.tabs.onRemoved.addListener(async (tabId) => {
  const { visits = [] } = await chrome.storage.local.get('visits');
  const openIndex = visits.findLastIndex(v => v.tabId === tabId && !v.endTime);
  if (openIndex >= 0) {
    visits[openIndex].endTime = Date.now();
    visits[openIndex].duration = Date.now() - visits[openIndex].startTime;
    await chrome.storage.local.set({ visits });
  }
});

// ─── Categorization ─────────────────────────────────────────────

async function categorize(domain) {
  const { customCategories = {} } = await chrome.storage.local.get('customCategories');

  // User overrides first
  if (customCategories[domain]) return customCategories[domain];

  // Built-in lists
  const productive = [
    'github.com', 'gitlab.com', 'stackoverflow.com', 'docs.google.com',
    'notion.so', 'figma.com', 'linear.app', 'jira.atlassian.net',
    'developer.mozilla.org', 'dart.dev', 'flutter.dev', 'medium.com',
    'coursera.org', 'udemy.com', 'leetcode.com', 'kaggle.com',
    'docs.python.org', 'console.cloud.google.com', 'vercel.com',
    'supabase.com', 'firebase.google.com', 'cloud.google.com',
  ];

  const distracting = [
    'youtube.com', 'reddit.com', 'twitter.com', 'x.com',
    'instagram.com', 'facebook.com', 'tiktok.com', 'twitch.tv',
    'netflix.com', 'hulu.com', 'disneyplus.com', 'amazon.com',
    'ebay.com', 'buzzfeed.com', '9gag.com', 'imgur.com',
  ];

  if (productive.some(p => domain.includes(p))) return 'productive';
  if (distracting.some(d => domain.includes(d))) return 'distracting';
  return 'neutral';
}

// ─── Today's Stats ──────────────────────────────────────────────

async function updateTodayStats() {
  const { visits = [] } = await chrome.storage.local.get('visits');
  const todayStart = new Date();
  todayStart.setHours(0, 0, 0, 0);

  const todayVisits = visits.filter(v => v.startTime >= todayStart.getTime());

  const stats = { productive: 0, neutral: 0, distracting: 0 };
  for (const v of todayVisits) {
    const duration = v.duration || (Date.now() - v.startTime);
    const minutes = duration / 60000;
    stats[v.category] = (stats[v.category] || 0) + minutes;
  }

  // Calculate Flow Score (productive / (productive + distracting) * 100)
  const total = stats.productive + stats.distracting;
  const flowScore = total > 0 ? Math.round((stats.productive / total) * 100) : 100;

  await chrome.storage.local.set({ todayStats: stats, flowScore });

  // Update badge
  const grade = flowScore >= 90 ? 'A' : flowScore >= 75 ? 'B' :
                flowScore >= 60 ? 'C' : flowScore >= 40 ? 'D' : 'F';

  await chrome.action.setBadgeText({ text: grade });
  await chrome.action.setBadgeBackgroundColor({ color: BADGE_COLORS[grade] });
}

// ─── Focus Mode (Block distracting sites) ───────────────────────

chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.type === 'TOGGLE_FOCUS') {
    (async () => {
      const { focusActive = false } = await chrome.storage.local.get('focusActive');
      if (focusActive) {
        await disableFocusBlocking();
        await chrome.storage.local.set({ focusActive: false });
        sendResponse({ focusActive: false });
      } else {
        await enableFocusBlocking();
        await chrome.storage.local.set({ focusActive: true });
        sendResponse({ focusActive: true });
      }
    })();
    return true; // Keep channel open for async response
  }

  if (message.type === 'GET_STATE') {
    (async () => {
      const state = await chrome.storage.local.get([
        'flowScore', 'todayStats', 'focusActive', 'visits',
      ]);
      sendResponse(state);
    })();
    return true;
  }

  if (message.type === 'CATEGORIZE_SITE') {
    (async () => {
      const { customCategories = {} } = await chrome.storage.local.get('customCategories');
      customCategories[message.domain] = message.category;
      await chrome.storage.local.set({ customCategories });
      await updateTodayStats();
      sendResponse({ ok: true });
    })();
    return true;
  }
});

async function enableFocusBlocking() {
  // Get distracting domains
  const { visits = [] } = await chrome.storage.local.get('visits');
  const distractingDomains = new Set();

  for (const v of visits) {
    if (v.category === 'distracting') {
      distractingDomains.add(v.domain);
    }
  }

  // Also add known distracting sites
  const known = [
    'youtube.com', 'reddit.com', 'twitter.com', 'x.com',
    'instagram.com', 'facebook.com', 'tiktok.com', 'twitch.tv',
  ];
  known.forEach(d => distractingDomains.add(d));

  // Create dynamic blocking rules
  const rules = [...distractingDomains].map((domain, i) => ({
    id: i + 1,
    priority: 1,
    action: { type: 'redirect', redirect: { extensionPath: '/blocked.html' } },
    condition: {
      urlFilter: `*://${domain}/*`,
      resourceTypes: ['main_frame'],
    },
  }));

  // Remove old rules, add new ones
  const existingRules = await chrome.declarativeNetRequest.getDynamicRules();
  const existingIds = existingRules.map(r => r.id);

  await chrome.declarativeNetRequest.updateDynamicRules({
    removeRuleIds: existingIds,
    addRules: rules,
  });

  console.log(`Focus mode ON: blocking ${rules.length} domains`);
}

async function disableFocusBlocking() {
  const existingRules = await chrome.declarativeNetRequest.getDynamicRules();
  const existingIds = existingRules.map(r => r.id);

  await chrome.declarativeNetRequest.updateDynamicRules({
    removeRuleIds: existingIds,
    addRules: [],
  });

  console.log('Focus mode OFF');
}

// ─── Alarms ─────────────────────────────────────────────────────

chrome.alarms.onAlarm.addListener(async (alarm) => {
  if (alarm.name === 'sync-to-supabase') {
    await syncToSupabase();
  }
  if (alarm.name === 'recalc-flow-score') {
    await updateTodayStats();
  }
});

// ─── Supabase Sync ──────────────────────────────────────────────

async function syncToSupabase() {
  const { supabaseUrl, supabaseKey, accessToken, userId } =
    await chrome.storage.local.get(['supabaseUrl', 'supabaseKey', 'accessToken', 'userId']);

  if (!supabaseUrl || !supabaseKey || !accessToken || !userId) return;

  const { visits = [], lastSyncTime = 0 } = await chrome.storage.local.get(['visits', 'lastSyncTime']);

  // Get visits since last sync
  const unsynced = visits.filter(v => v.endTime && v.endTime > lastSyncTime && v.duration > 5000);
  if (unsynced.length === 0) return;

  try {
    const payload = unsynced.map(v => ({
      id: crypto.randomUUID(),
      user_id: userId,
      domain: v.domain,
      url: v.url,
      title: v.title,
      category: v.category,
      started_at: new Date(v.startTime).toISOString(),
      ended_at: new Date(v.endTime).toISOString(),
      duration_seconds: Math.round(v.duration / 1000),
      device_id: 'chrome-extension',
    }));

    const res = await fetch(`${supabaseUrl}/rest/v1/browsing_sessions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': supabaseKey,
        'Authorization': `Bearer ${accessToken}`,
        'Prefer': 'return=minimal',
      },
      body: JSON.stringify(payload),
    });

    if (res.ok) {
      await chrome.storage.local.set({ lastSyncTime: Date.now() });
      console.log(`Synced ${payload.length} browsing sessions`);
    } else {
      console.error('Sync failed:', res.status, await res.text());
    }
  } catch (err) {
    console.error('Sync error:', err);
  }
}
