/**
 * Cat Talk Agent War Room — Frontend JS
 * Fetches /api/status every 5 seconds and updates the dashboard.
 */

const REFRESH_INTERVAL = 5000; // ms

// ============================================================
// Utility
// ============================================================

function el(id) {
  return document.getElementById(id);
}

function setText(id, text) {
  const el2 = el(id);
  if (el2) el2.textContent = text;
}

function setHTML(id, html) {
  const el2 = el(id);
  if (el2) el2.innerHTML = html;
}

function timeAgo(ms) {
  if (!ms) return '—';
  const diff = Date.now() - ms;
  if (diff < 0) return 'in ' + Math.abs(Math.floor(diff / 60000)) + 'm';
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return 'just now';
  if (mins < 60) return mins + 'm ago';
  const hrs = Math.floor(mins / 60);
  return hrs + 'h ago';
}

function formatTime(isoString) {
  if (!isoString) return '—';
  try {
    const d = new Date(isoString);
    return d.toLocaleTimeString('zh-TW', { hour: '2-digit', minute: '2-digit', second: '2-digit' });
  } catch {
    return isoString;
  }
}

// ============================================================
// Render helpers
// ============================================================

function getOpenClawStatus(data) {
  if (data.can_openclaw_continue) return 'ready';
  if (data.handoff_status === 'WAITING_FOR_HERMES') return 'waiting_hermes';
  return 'idle';
}

function getHermesStatus(data) {
  const r = data.hermes_review_result;
  if (r === 'PASS') return 'pass';
  if (r === 'FAIL') return 'fail';
  return 'idle';
}

function renderOpenClawCard(data) {
  const card = el('openclav-card');
  const status = getOpenClawStatus(data);

  // Remove all status classes
  card.className = 'agent-card openclaw-card status-' + status;

  // Status badge
  const statusMap = {
    ready: '✅ Ready',
    waiting_hermes: '⏳ Waiting Hermes',
    idle: '🐾 Idle',
    working: '⚙️ Working',
    blocked: '🚫 Blocked',
  };
  setText('openclav-status', statusMap[status] || status);
  setText('openclav-task', data.decision_text || '—');

  // Avatar badges
  const badgeMap = {
    ready: '🐾',
    waiting_hermes: '⏳',
    idle: '💻',
    working: '⚙️',
    blocked: '🚫',
  };
  setHTML('openclav-badges', badgeMap[status] || '');
}

function renderHermesCard(data) {
  const card = el('hermes-card');
  const status = getHermesStatus(data);

  // Remove all status classes, re-apply
  card.className = 'agent-card hermes-card status-' + status;

  // Status badge
  const statusMap = {
    pass: '✅ PASS',
    fail: '❌ FAIL',
    idle: '🪽 Idle',
    reviewing: '🔍 Reviewing',
  };
  setText('hermes-status', statusMap[status] || status);

  // Task
  const taskName = data.latest_review_task || '—';
  setText('hermes-task', taskName);

  // Avatar badges
  const badgeMap = {
    pass: '✅',
    fail: '❌',
    idle: '🪽',
    reviewing: '🔍',
  };
  setHTML('hermes-badges', badgeMap[status] || '');
}

function renderCentralPanel(data) {
  // Decision light
  const light = el('decision-light');
  const label = el('decision-label');

  let lightClass = 'light-gray';
  let lightEmoji = '⏳';
  let labelText = 'Checking...';

  if (data.can_openclaw_continue) {
    lightClass = 'light-green';
    lightEmoji = '🟢';
    labelText = 'OpenClaw may continue';
  } else if (data.handoff_status === 'WAITING_FOR_HERMES') {
    lightClass = 'light-yellow';
    lightEmoji = '🟡';
    labelText = 'Waiting for Hermes...';
  } else if (data.hermes_review_result === 'FAIL') {
    lightClass = 'light-red';
    lightEmoji = '🔴';
    labelText = 'OpenClaw must fix error';
  }

  light.className = 'decision-light ' + lightClass;
  light.textContent = lightEmoji;
  label.textContent = labelText;

  // Handoff info
  setText('handoff-status', data.handoff_status || '—');
  setText('waiting-status', data.waiting_for_hermes ? 'YES' : 'NO');
  setText('review-result', data.hermes_review_result || '—');
  setText('can-continue', data.can_openclaw_continue ? 'YES' : 'NO');

  // Color code can-continue
  const ccEl = el('can-continue');
  ccEl.style.color = data.can_openclaw_continue ? '#69f0ae' : '#ff5252';

  // Latest commit
  const commits = data.recent_commits || [];
  if (commits.length > 0) {
    const latest = commits[0];
    setText('latest-commit', latest.hash.substring(0, 7) + ' ' + latest.message);
  } else {
    setText('latest-commit', '—');
  }
}

function renderRecentCommits(data) {
  const commits = data.recent_commits || [];
  if (commits.length === 0) {
    setHTML('recent-commits', '<div class="log-line">No commits</div>');
    return;
  }
  const html = commits.slice(0, 8).map(c =>
    '<div class="log-line"><span class="hash">' + c.hash.substring(0,7) + '</span> ' + c.message + '</div>'
  ).join('');
  setHTML('recent-commits', html);
}

function renderCronRuns(data) {
  const raw = data.recent_cron_runs_raw || '';
  if (!raw) {
    setHTML('cron-runs', '<div class="log-line">No runs recorded</div>');
    return;
  }
  // Parse simple line-based output
  const lines = raw.split('\n').filter(l => l.trim());
  const html = lines.slice(0, 10).map(line => {
    // Highlight PASS/FAIL/error keywords
    const highlighted = line
      .replace(/PASS/g, '<span style="color:#69f0ae">PASS</span>')
      .replace(/FAIL/g, '<span style="color:#ff5252">FAIL</span>')
      .replace(/error/gi, '<span style="color:#ff5252">error</span>')
      .replace(/finished/g, '<span style="color:#4fc3f7">finished</span>');
    return '<div class="log-line">' + highlighted + '</div>';
  }).join('');
  setHTML('cron-runs', html || '<div class="log-line">No runs recorded</div>');
}

function renderGitStatus(data) {
  const gs = data.git_status || {};
  if (gs.is_clean) {
    setHTML('git-status', '<div class="log-line git-clean">✅ Clean — no uncommitted changes</div>');
  } else if (gs.has_changes) {
    const lines = gs.output.split('\n').filter(l => l.trim()).slice(0, 10);
    const html = lines.map(l =>
      '<div class="log-line git-dirty">' + l + '</div>'
    ).join('');
    setHTML('git-status', html || '<div class="log-line">Unknown status</div>');
  } else {
    setHTML('git-status', '<div class="log-line">—</div>');
  }
}

function renderFooter(data) {
  const last = data.current_time ? formatTime(data.current_time) : '—';
  setText('last-updated', 'Last updated: ' + last);
  setText('current-time', '⏰ ' + (data.current_time ? formatTime(data.current_time) : '—'));
}

// ============================================================
// Main fetch & render
// ============================================================

let errorCount = 0;

async function fetchStatus() {
  try {
    const resp = await fetch('/api/status', { cache: 'no-cache' });
    if (!resp.ok) throw new Error('HTTP ' + resp.status);

    const data = await resp.json();
    errorCount = 0;

    renderOpenClawCard(data);
    renderHermesCard(data);
    renderCentralPanel(data);
    renderRecentCommits(data);
    renderCronRuns(data);
    renderGitStatus(data);
    renderFooter(data);

    // Show connection error banner if it was shown
    const banner = el('conn-error');
    if (banner) banner.style.display = 'none';

  } catch (err) {
    console.warn('Fetch error:', err);
    errorCount++;

    if (errorCount >= 3) {
      // Show persistent error
      let banner = el('conn-error');
      if (!banner) {
        banner = document.createElement('div');
        banner.id = 'conn-error';
        banner.style.cssText = 'position:fixed;top:0;left:0;right:0;background:#ff5252;color:#fff;text-align:center;padding:8px;font-size:0.9rem;z-index:999';
        document.body.prepend(banner);
      }
      banner.textContent = '⚠️ Connection lost. Retrying...';
      banner.style.display = 'block';
    }
  }
}

// ============================================================
// Bootstrap
// ============================================================

// Route / to serve index.html
async function init() {
  // Override root route in app.py by fetching status to confirm API is up
  await fetchStatus();

  // Refresh every 5 seconds
  setInterval(fetchStatus, REFRESH_INTERVAL);
}

document.addEventListener('DOMContentLoaded', init);