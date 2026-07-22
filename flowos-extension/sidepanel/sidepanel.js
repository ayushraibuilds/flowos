// FlowOS Side Panel — full dashboard with timeline, breakdown, top sites.

document.addEventListener('DOMContentLoaded', async () => {
  await loadDashboard();
  setupListeners();

  // Auto-refresh every 30 seconds
  setInterval(loadDashboard, 30000);
});

async function loadDashboard() {
  const state = await chrome.runtime.sendMessage({ type: 'GET_STATE' });
  const { flowScore = 0, todayStats = {}, focusActive = false, visits = [] } = state || {};

  // Score ring
  const grade = flowScore >= 90 ? 'A' : flowScore >= 75 ? 'B' :
                flowScore >= 60 ? 'C' : flowScore >= 40 ? 'D' : 'F';

  const gradeColors = { A: '#00D68F', B: '#4A9EFF', C: '#FFB74D', D: '#FF8A65', F: '#FF6B6B' };

  document.getElementById('scoreGrade').textContent = grade;
  document.getElementById('scoreGrade').style.color = gradeColors[grade];
  document.getElementById('scoreValue').textContent = `${flowScore}%`;

  // Score ring conic gradient
  const ring = document.getElementById('scoreRing');
  ring.style.background = `conic-gradient(${gradeColors[grade]} ${flowScore}%, #1A2230 ${flowScore}%)`;

  // Breakdown stats
  const prod = Math.round(todayStats.productive || 0);
  const neut = Math.round(todayStats.neutral || 0);
  const dist = Math.round(todayStats.distracting || 0);

  document.getElementById('prodMinutes').textContent = `${prod}m`;
  document.getElementById('neutMinutes').textContent = `${neut}m`;
  document.getElementById('distMinutes').textContent = `${dist}m`;

  // Breakdown bar
  const total = prod + neut + dist;
  const bar = document.getElementById('breakdownBar');
  if (total > 0) {
    bar.innerHTML = `
      <div class="bar-segment productive" style="width: ${(prod/total*100).toFixed(1)}%"></div>
      <div class="bar-segment neutral" style="width: ${(neut/total*100).toFixed(1)}%"></div>
      <div class="bar-segment distracting" style="width: ${(dist/total*100).toFixed(1)}%"></div>
    `;
  } else {
    bar.innerHTML = '<div class="bar-segment neutral" style="width: 100%"></div>';
  }

  // Timeline
  renderTimeline(visits);

  // Top sites
  renderTopSites(visits);

  // Focus button
  const focusBtn = document.getElementById('focusToggle');
  if (focusActive) {
    focusBtn.textContent = '🔓 Stop Focus Mode';
    focusBtn.className = 'focus-btn active';
  } else {
    focusBtn.textContent = '🔒 Start Focus Mode';
    focusBtn.className = 'focus-btn';
  }
}

function renderTimeline(visits) {
  const container = document.getElementById('timeline');
  const todayStart = new Date();
  todayStart.setHours(0, 0, 0, 0);

  const todayVisits = visits
    .filter(v => v.startTime >= todayStart.getTime())
    .sort((a, b) => b.startTime - a.startTime)
    .slice(0, 30);

  if (todayVisits.length === 0) {
    container.innerHTML = '<div class="empty-state">No browsing data yet today</div>';
    return;
  }

  container.textContent = '';
  for (const v of todayVisits) {
    const time = new Date(v.startTime).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    const durationMs = v.duration || (Date.now() - v.startTime);
    const minutes = Math.round(durationMs / 60000);
    const durationStr = minutes < 1 ? '<1m' : `${minutes}m`;

    const item = document.createElement('div');
    item.className = 'timeline-item';

    const dot = document.createElement('div');
    dot.className = `timeline-dot ${v.category}`;

    const info = document.createElement('div');
    info.className = 'timeline-info';

    const domainDiv = document.createElement('div');
    domainDiv.className = 'timeline-domain';
    domainDiv.textContent = v.domain;

    const timeDiv = document.createElement('div');
    timeDiv.className = 'timeline-time';
    timeDiv.textContent = time;

    info.appendChild(domainDiv);
    info.appendChild(timeDiv);

    const durationDiv = document.createElement('div');
    durationDiv.className = 'timeline-duration';
    durationDiv.textContent = durationStr;

    item.appendChild(dot);
    item.appendChild(info);
    item.appendChild(durationDiv);
    container.appendChild(item);
  }
}

function renderTopSites(visits) {
  const container = document.getElementById('topSitesList');
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
    .slice(0, 10);

  if (sorted.length === 0) {
    container.textContent = '';
    const empty = document.createElement('div');
    empty.className = 'empty-state';
    empty.textContent = 'No data yet';
    container.appendChild(empty);
    return;
  }

  container.textContent = '';
  sorted.forEach((site, i) => {
    const minutes = Math.round(site.totalMs / 60000);
    const row = document.createElement('div');
    row.className = 'site-row';

    const rank = document.createElement('span');
    rank.className = 'site-rank';
    rank.textContent = `${i + 1}`;

    const dot = document.createElement('span');
    dot.className = `site-dot ${site.category}`;

    const domain = document.createElement('span');
    domain.className = 'site-domain';
    domain.textContent = site.domain;

    const time = document.createElement('span');
    time.className = 'site-time';
    time.textContent = `${minutes}m`;

    row.appendChild(rank);
    row.appendChild(dot);
    row.appendChild(domain);
    row.appendChild(time);
    container.appendChild(row);
  });
}

function setupListeners() {
  document.getElementById('focusToggle').addEventListener('click', async () => {
    await chrome.runtime.sendMessage({ type: 'TOGGLE_FOCUS' });
    await loadDashboard();
  });
}
