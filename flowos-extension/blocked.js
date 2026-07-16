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

document.addEventListener('DOMContentLoaded', () => {
  // Random quote
  const quote = quotes[Math.floor(Math.random() * quotes.length)];
  document.getElementById('quoteText').textContent = `"${quote.text}"`;
  document.getElementById('quoteAuthor').textContent = `— ${quote.author}`;

  // Go back
  document.getElementById('goBackBtn').addEventListener('click', () => {
    history.back();
  });

  // Override
  document.getElementById('overrideBtn').addEventListener('click', () => {
    document.getElementById('overrideWarning').style.display = 'block';
  });

  // Confirm override
  document.getElementById('confirmOverride').addEventListener('click', async () => {
    // Log the escape hatch usage
    const { escapeHatchCount = 0 } = await chrome.storage.local.get('escapeHatchCount');
    await chrome.storage.local.set({ escapeHatchCount: escapeHatchCount + 1 });

    // Disable blocking temporarily (30 seconds)
    await chrome.runtime.sendMessage({ type: 'TEMPORARY_BYPASS', seconds: 30 });

    // Go back (the site will now load)
    history.back();
  });
});
