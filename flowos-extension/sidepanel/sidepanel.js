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

  container.innerHTML = todayVisits.map(v => {
    const time = new Date(v.startTime).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    const durationMs = v.duration || (Date.now() - v.startTime);
    const minutes = Math.round(durationMs / 60000);
    const durationStr = minutes < 1 ? '<1m' : `${minutes}m`;

    return `
      <div class="timeline-item">
        <div class="timeline-dot ${v.category}"></div>
        <div class="timeline-info">
          <div class="timeline-domain">${v.domain}</div>
          <div class="timeline-time">${time}</div>
        </div>
        <div class="timeline-duration">${durationStr}</div>
      </div>
    `;
  }).join('');
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
    container.innerHTML = '<div class="empty-state">No data yet</div>';
    return;
  }

  container.innerHTML = sorted.map((site, i) => {
    const minutes = Math.round(site.totalMs / 60000);
    return `
      <div class="site-row">
        <span class="site-rank">${i + 1}</span>
        <span class="site-dot ${site.category}"></span>
        <span class="site-domain">${site.domain}</span>
        <span class="site-time">${minutes}m</span>
      </div>
    `;
  }).join('');
}

function setupListeners() {
  document.getElementById('focusToggle').addEventListener('click', async () => {
    await chrome.runtime.sendMessage({ type: 'TOGGLE_FOCUS' });
    await loadDashboard();
  });
}
