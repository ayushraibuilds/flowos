// FlowOS Popup — quick-glance Flow Score, stats, focus toggle.
// Rule #5: async/await only, no .then() chains.

document.addEventListener('DOMContentLoaded', async () => {
  await loadState();
  setupListeners();
});

async function loadState() {
  const state = await chrome.runtime.sendMessage({ type: 'GET_STATE' });

  const { flowScore = 0, todayStats = {}, focusActive = false, visits = [] } = state || {};

  // Grade
  const grade = flowScore >= 90 ? 'A' : flowScore >= 75 ? 'B' :
                flowScore >= 60 ? 'C' : flowScore >= 40 ? 'D' : 'F';

  const gradeEl = document.getElementById('gradeDisplay');
  gradeEl.textContent = grade;
  gradeEl.className = `grade ${grade}`;

  // Stats
  const productive = Math.round(todayStats.productive || 0);
  const neutral = Math.round(todayStats.neutral || 0);
  const distracting = Math.round(todayStats.distracting || 0);

  document.getElementById('productiveTime').textContent = `${productive}m`;
  document.getElementById('neutralTime').textContent = `${neutral}m`;
  document.getElementById('distractingTime').textContent = `${distracting}m`;

  // Focus button
  const focusBtn = document.getElementById('focusBtn');
  if (focusActive) {
    focusBtn.textContent = '🔓 Stop Focus Mode';
    focusBtn.className = 'focus-btn on';
  } else {
    focusBtn.textContent = '🔒 Start Focus Mode';
    focusBtn.className = 'focus-btn off';
  }

  // Top sites
  renderTopSites(visits);
}

function renderTopSites(visits) {
  const container = document.getElementById('topSites');
  const todayStart = new Date();
  todayStart.setHours(0, 0, 0, 0);

  const todayVisits = visits.filter(v => v.startTime >= todayStart.getTime());

  // Aggregate by domain
  const domainMap = {};
  for (const v of todayVisits) {
    if (!domainMap[v.domain]) {
      domainMap[v.domain] = { domain: v.domain, category: v.category, totalMs: 0 };
    }
    domainMap[v.domain].totalMs += v.duration || (Date.now() - v.startTime);
  }

  const sorted = Object.values(domainMap)
    .sort((a, b) => b.totalMs - a.totalMs)
    .slice(0, 5);

  // Clear existing rows (keep the h3)
  const h3 = container.querySelector('h3');
  container.innerHTML = '';
  container.appendChild(h3);

  for (const site of sorted) {
    const minutes = Math.round(site.totalMs / 60000);
    if (minutes < 1) continue;

    const row = document.createElement('div');
    row.className = 'site-row';
    row.innerHTML = `
      <span class="site-domain">
        <span class="site-dot ${site.category}"></span>
        ${site.domain}
      </span>
      <span class="site-time">${minutes}m</span>
    `;
    container.appendChild(row);
  }

  if (sorted.length === 0 || sorted.every(s => Math.round(s.totalMs / 60000) < 1)) {
    const empty = document.createElement('div');
    empty.style.cssText = 'text-align: center; color: #4A5568; font-size: 12px; padding: 16px;';
    empty.textContent = 'No browsing data yet today';
    container.appendChild(empty);
  }
}

function setupListeners() {
  // Focus toggle
  document.getElementById('focusBtn').addEventListener('click', async () => {
    const result = await chrome.runtime.sendMessage({ type: 'TOGGLE_FOCUS' });
    await loadState(); // Refresh UI
  });

  // Settings
  document.getElementById('settingsBtn').addEventListener('click', () => {
    chrome.runtime.openOptionsPage();
  });

  // Side panel
  document.getElementById('openSidePanel').addEventListener('click', async (e) => {
    e.preventDefault();
    const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
    await chrome.sidePanel.open({ windowId: tab.windowId });
    window.close(); // Close popup
  });
}
