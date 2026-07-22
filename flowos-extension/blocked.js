// FlowOS Blocked Page — escape hatch with XP cost.

const quotes = [
  { text: "The successful warrior is the average man, with laser-like focus.", author: "Bruce Lee" },
  { text: "Lack of direction, not lack of time, is the problem.", author: "Zig Ziglar" },
  { text: "It is during our darkest moments that we must focus to see the light.", author: "Aristotle" },
  { text: "Do not dwell in the past, do not dream of the future, concentrate the mind on the present moment.", author: "Buddha" },
  { text: "The main thing is to keep the main thing the main thing.", author: "Stephen Covey" },
  { text: "You can always find a distraction if you're looking for one.", author: "Tom Kite" },
  { text: "Where focus goes, energy flows.", author: "Tony Robbins" },
  { text: "Starve your distractions, feed your focus.", author: "Unknown" },
];

document.addEventListener('DOMContentLoaded', async () => {
  // Random quote
  const quote = quotes[Math.floor(Math.random() * quotes.length)];
  document.getElementById('quoteText').textContent = `"${quote.text}"`;
  document.getElementById('quoteAuthor').textContent = `— ${quote.author}`;

  // Parse original target URL from query parameter
  const params = new URLSearchParams(window.location.search);
  const originalUrl = params.get('url');
  let targetDomain = '';
  if (originalUrl) {
    try {
      targetDomain = new URL(originalUrl).hostname.replace('www.', '');
    } catch (_) {}
  }

  // Check protection mode (nudge, guard, deep)
  const { protectionMode = 'guard' } = await chrome.storage.local.get('protectionMode');
  const overrideBtn = document.getElementById('overrideBtn');
  if (protectionMode === 'deep' && overrideBtn) {
    overrideBtn.style.display = 'none';
    const subtitle = document.querySelector('.subtitle');
    if (subtitle) {
      subtitle.textContent = 'Deep Work Mode is active. Bypasses are disabled for this session.';
    }
  }

  // Go back button
  document.getElementById('goBackBtn').addEventListener('click', () => {
    if (history.length > 1) {
      history.back();
    } else {
      window.close();
    }
  });

  // Override button
  if (overrideBtn) {
    overrideBtn.addEventListener('click', () => {
      document.getElementById('overrideWarning').style.display = 'block';
    });
  }

  // Confirm override
  document.getElementById('confirmOverride').addEventListener('click', async () => {
    // Log the escape hatch usage
    const { escapeHatchCount = 0 } = await chrome.storage.local.get('escapeHatchCount');
    await chrome.storage.local.set({ escapeHatchCount: escapeHatchCount + 1 });

    // Send TEMPORARY_BYPASS message for this specific domain
    await chrome.runtime.sendMessage({
      type: 'TEMPORARY_BYPASS',
      seconds: 30,
      domain: targetDomain,
    });

    // Navigate to original URL directly (or history.back as fallback)
    if (originalUrl) {
      window.location.href = originalUrl;
    } else if (history.length > 1) {
      history.back();
    }
  });
});
