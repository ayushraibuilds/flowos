// FlowOS Service Worker — background tracking, sync, focus mode.
// Rule #7: NO global variable state. All state in chrome.storage.

importScripts('config.js');

// ─── Storage Lock Mutex ─────────────────────────────────────────

let storageLockChain = Promise.resolve();

function withStorageLock(fn) {
  const result = storageLockChain.then(() => fn());
  storageLockChain = result.catch(() => {});
  return result;
}

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

  // Set up active focus session sync alarm (every 1 minute)
  await chrome.alarms.create('sync-focus-state', {
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

  await withStorageLock(async () => {
    const { visits = [] } = await chrome.storage.local.get('visits');

    // Close previous visit for this tab (or update if same domain)
    const prevIndex = visits.findLastIndex(v => v.tabId === tabId && !v.endTime);
    if (prevIndex >= 0) {
      const prev = visits[prevIndex];
      if (prev.domain === domain) {
        // Same domain navigation — update url/title without splitting visit duration
        prev.url = tab.url;
        prev.title = tab.title || domain;
        await chrome.storage.local.set({ visits });
        return;
      }
      prev.endTime = timestamp;
      prev.duration = timestamp - prev.startTime;
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
  });

  // Update today's stats
  await updateTodayStats();
});

// Close visit when tab closes
chrome.tabs.onRemoved.addListener(async (tabId) => {
  await withStorageLock(async () => {
    const { visits = [] } = await chrome.storage.local.get('visits');
    const openIndex = visits.findLastIndex(v => v.tabId === tabId && !v.endTime);
    if (openIndex >= 0) {
      visits[openIndex].endTime = Date.now();
      visits[openIndex].duration = Date.now() - visits[openIndex].startTime;
      await chrome.storage.local.set({ visits });
    }
  });
});

// ─── Categorization ─────────────────────────────────────────────

function matchesDomainList(domain, list) {
  return list.some(d => domain === d || domain.endsWith('.' + d));
}

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

  if (matchesDomainList(domain, productive)) return 'productive';
  if (matchesDomainList(domain, distracting)) return 'distracting';
  return 'neutral';
}

// ─── Today's Stats ──────────────────────────────────────────────

async function updateTodayStats() {
  await withStorageLock(async () => {
    const { visits = [] } = await chrome.storage.local.get('visits');
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);

    const todayVisits = visits.filter(v => v.startTime >= todayStart.getTime());

    // Deduplicate overlapping visits per domain so multi-tabs don't double-count
    const domainIntervals = {};
    for (const v of todayVisits) {
      const start = v.startTime;
      const end = v.endTime || Date.now();
      if (!domainIntervals[v.domain]) {
        domainIntervals[v.domain] = { category: v.category, intervals: [] };
      }
      domainIntervals[v.domain].intervals.push([start, end]);
    }

    const stats = { productive: 0, neutral: 0, distracting: 0 };

    for (const { category, intervals } of Object.values(domainIntervals)) {
      if (intervals.length === 0) continue;
      // Sort and merge overlapping intervals
      intervals.sort((a, b) => a[0] - b[0]);
      const merged = [intervals[0]];
      for (let i = 1; i < intervals.length; i++) {
        const last = merged[merged.length - 1];
        const current = intervals[i];
        if (current[0] <= last[1]) {
          last[1] = Math.max(last[1], current[1]);
        } else {
          merged.push(current);
        }
      }
      let totalMs = 0;
      for (const [s, e] of merged) {
        totalMs += (e - s);
      }
      stats[category] = (stats[category] || 0) + (totalMs / 60000);
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
  });
}

// ─── Focus Mode (Block distracting sites) ───────────────────────

chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.type === 'TOGGLE_FOCUS') {
    (async () => {
      const { focusActive = false } = await chrome.storage.local.get('focusActive');
      const now = Date.now();
      if (focusActive) {
        await disableFocusBlocking();
        await chrome.storage.local.set({ focusActive: false, lastManualToggleAt: now });
        sendResponse({ focusActive: false });
      } else {
        await enableFocusBlocking();
        await chrome.storage.local.set({ focusActive: true, lastManualToggleAt: now });
        sendResponse({ focusActive: true });
      }
    })();
    return true; // Keep channel open for async response
  }

  if (message.type === 'TEMPORARY_BYPASS') {
    (async () => {
      // Validate sender origin: must strictly originate from our own extension blocked.html page
      const blockedPageUrl = chrome.runtime.getURL('blocked.html');
      if (!sender.url || !sender.url.startsWith(blockedPageUrl)) {
        sendResponse({ ok: false, error: 'Unauthorized sender' });
        return;
      }

      const domain = message.domain;
      const { focusActive = false } = await chrome.storage.local.get('focusActive');
      if (focusActive && domain) {
        // Create a temporary high-priority allow rule (ID 9999) for this specific target domain only
        const allowRule = {
          id: 9999,
          priority: 100,
          action: { type: 'allow' },
          condition: {
            urlFilter: `*://${domain}/*`,
            resourceTypes: ['main_frame'],
          },
        };
        await chrome.declarativeNetRequest.updateDynamicRules({
          removeRuleIds: [9999],
          addRules: [allowRule],
        });
        // Rearm (remove allow rule) in 30 seconds
        await chrome.alarms.create('rearm-blocking', { delayInMinutes: 0.5 });
      }
      sendResponse({ ok: true });
    })();
    return true;
  }

  if (message.type === 'SYNC_FOCUS_STATE') {
    (async () => {
      await syncFocusState();
      sendResponse({ ok: true });
    })();
    return true;
  }

  if (message.type === 'GET_STATE') {
    (async () => {
      const state = await chrome.storage.local.get([
        'flowScore', 'todayStats', 'focusActive', 'visits', 'protectionMode',
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

  // Create dynamic blocking rules with original target URL encoded in query string
  const rules = [...distractingDomains].map((domain, i) => ({
    id: i + 1,
    priority: 1,
    action: {
      type: 'redirect',
      redirect: { extensionPath: `/blocked.html?url=${encodeURIComponent(`https://${domain}`)}` },
    },
    condition: {
      urlFilter: `*://${domain}/*`,
      resourceTypes: ['main_frame'],
    },
  }));

  // Remove old rules, add new ones (preserve bypass rule 9999 if active)
  const existingRules = await chrome.declarativeNetRequest.getDynamicRules();
  const existingIds = existingRules.map(r => r.id).filter(id => id !== 9999);

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
  if (alarm.name === 'sync-focus-state') {
    await syncFocusState();
  }
  if (alarm.name === 'rearm-blocking') {
    // Remove temporary bypass allow rule (ID 9999)
    await chrome.declarativeNetRequest.updateDynamicRules({
      removeRuleIds: [9999],
    });
  }
});

// ─── Supabase Sync ──────────────────────────────────────────────

async function getSupabaseConfig() {
  const local = await chrome.storage.local.get(['supabaseUrl', 'supabasePublishableKey']);
  const config = globalThis.FLOWOS_CONFIG || {};
  return {
    supabaseUrl: local.supabaseUrl || config.supabaseUrl || '',
    supabasePublishableKey: local.supabasePublishableKey || config.supabasePublishableKey || '',
  };
}

async function syncToSupabase() {
  const config = await getSupabaseConfig();
  if (!config.supabaseUrl || !config.supabasePublishableKey) return;

  const session = await getValidSession(config.supabaseUrl, config.supabasePublishableKey);
  if (!session) return;

  const { accessToken, userId } = session;

  if (!accessToken || !userId) return;

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

    const res = await fetch(`${config.supabaseUrl}/rest/v1/browsing_sessions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': config.supabasePublishableKey,
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

async function getValidSession(supabaseUrl, supabasePublishableKey) {
  const { accessToken, refreshToken, tokenExpiresAt, userId } =
    await chrome.storage.local.get(['accessToken', 'refreshToken', 'tokenExpiresAt', 'userId']);

  // Keep a one-minute margin so a token cannot expire during the sync request.
  if (accessToken && userId && (!tokenExpiresAt || tokenExpiresAt > Date.now() + 60_000)) {
    return { accessToken, userId };
  }

  if (!refreshToken) return null;

  try {
    const res = await fetch(`${supabaseUrl}/auth/v1/token?grant_type=refresh_token`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': supabasePublishableKey,
      },
      body: JSON.stringify({ refresh_token: refreshToken }),
    });

    if (!res.ok) {
      await chrome.storage.local.remove(['accessToken', 'refreshToken', 'tokenExpiresAt', 'userId']);
      return null;
    }

    const data = await res.json();
    const refreshedUserId = data.user?.id || userId;
    if (!data.access_token || !refreshedUserId) return null;

    await chrome.storage.local.set({
      accessToken: data.access_token,
      refreshToken: data.refresh_token || refreshToken,
      tokenExpiresAt: Date.now() + ((data.expires_in || 0) * 1000),
      userId: refreshedUserId,
    });
    return { accessToken: data.access_token, userId: refreshedUserId };
  } catch (err) {
    console.error('Session refresh error:', err);
    return null;
  }
}

// ─── Focus Session Active State Sync ───────────────────────────

async function syncFocusState() {
  const { isPaired = false, userId, focusActive = false, lastManualToggleAt = 0 } =
    await chrome.storage.local.get(['isPaired', 'userId', 'focusActive', 'lastManualToggleAt']);

  if (!isPaired || !userId) return;

  // Respect manual override: skip sync if manual toggle happened within last 5 minutes
  if (Date.now() - lastManualToggleAt < 5 * 60 * 1000) return;

  const config = await getSupabaseConfig();
  if (!config.supabaseUrl || !config.supabasePublishableKey) return;

  const session = await getValidSession(config.supabaseUrl, config.supabasePublishableKey);
  if (!session) return;

  try {
    const res = await fetch(`${config.supabaseUrl}/rest/v1/focus_sessions?user_id=eq.${userId}&completed_at=is.null`, {
      method: 'GET',
      headers: {
        'apikey': config.supabasePublishableKey,
        'Authorization': `Bearer ${session.accessToken}`,
      },
    });

    if (res.ok) {
      const activeSessions = await res.json();
      const hasActive = activeSessions && activeSessions.length > 0;
      const protectionMode = activeSessions && activeSessions[0]?.protection_mode ? activeSessions[0].protection_mode : 'guard';

      await chrome.storage.local.set({ protectionMode });

      if (hasActive && !focusActive) {
        await enableFocusBlocking();
        await chrome.storage.local.set({ focusActive: true });
        console.log('Sync Focus: Active session detected, enabled blocking');
      } else if (!hasActive && focusActive) {
        await disableFocusBlocking();
        await chrome.storage.local.set({ focusActive: false });
        console.log('Sync Focus: No active session, disabled blocking');
      }
    }
  } catch (err) {
    console.error('Focus state sync error:', err);
  }
}
