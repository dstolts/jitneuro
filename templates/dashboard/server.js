// JitNeuro Agent Dashboard Server
// Zero-dependency Node.js HTTP server for live agent monitoring.
//
// Usage: node server.js [--port=9847] [--no-open]
// Env:   JITDASH_PORT=9847  JITDASH_DIR=<workspace>/.claude/dashboard

const http = require('http');
const fs = require('fs');
const path = require('path');
const os = require('os');
const { exec } = require('child_process');

// -- Configuration --

const DEFAULT_PORT = 9847;
const DEFAULT_DIR = path.join(os.homedir(), '.claude', 'dashboard');

function hasFlag(name) {
  return process.argv.slice(2).includes('--' + name);
}

function getFlag(name, fallback) {
  for (var arg of process.argv.slice(2)) {
    if (arg.startsWith('--' + name + '=')) return arg.split('=').slice(1).join('=');
  }
  return fallback;
}

var PORT = parseInt(getFlag('port', process.env.JITDASH_PORT || DEFAULT_PORT), 10);
var NO_OPEN = hasFlag('no-open');
var DATA_DIR = getFlag('dir', process.env.JITDASH_DIR || DEFAULT_DIR);
var RUNS_DIR = path.join(DATA_DIR, 'runs');
var HTML_FILE = path.join(__dirname, 'dashboard.html');

// Sessions: sibling of DATA_DIR's parent (e.g., .claude/session-state beside .claude/dashboard)
var SESSIONS_DIR = getFlag('sessions', process.env.JITDASH_SESSIONS || path.join(DATA_DIR, '..', 'session-state'));

// Settings: jitneuro-settings.json in the .claude root (sibling of dashboard/)
var SETTINGS_FILE = path.join(DATA_DIR, '..', 'jitneuro-settings.json');

var ARCHIVE_DIR = path.join(RUNS_DIR, '.archive');
fs.mkdirSync(RUNS_DIR, { recursive: true });
fs.mkdirSync(ARCHIVE_DIR, { recursive: true });

// -- Settings defaults --
// archiveCompletedMs: move completed runs to archive after this delay (default: 0 = immediately)
// archiveTtlMs: delete archived runs after this delay (default: 1800000 = 30 minutes)

function getArchiveCompletedMs() {
  var s = getSettings();
  return (s.dashboard && s.dashboard.archiveCompletedMs != null) ? s.dashboard.archiveCompletedMs : 0;
}

function getArchiveTtlMs() {
  var s = getSettings();
  return (s.dashboard && s.dashboard.archiveTtlMs != null) ? s.dashboard.archiveTtlMs : 1800000;
}

// -- Auto-archive and purge --

function archiveAndPurge() {
  var now = Date.now();
  var archiveDelay = getArchiveCompletedMs();
  var purgeTtl = getArchiveTtlMs();

  // Mark completed runs as archived (in-place, no file move)
  var entries;
  try { entries = fs.readdirSync(RUNS_DIR, { withFileTypes: true }); }
  catch (e) { entries = []; }

  for (var i = 0; i < entries.length; i++) {
    var entry = entries[i];
    if (!entry.isDirectory() || entry.name === '.archive') continue;

    var runDir = path.join(RUNS_DIR, entry.name);
    var meta = readJsonSafe(path.join(runDir, 'meta.json')) || {};
    if (meta.archivedAt) continue; // already marked

    var agentsDir = path.join(runDir, 'agents');
    var agentFiles;
    try { agentFiles = fs.readdirSync(agentsDir).filter(function(f) { return f.endsWith('.json'); }); }
    catch (e) { agentFiles = []; }

    var agents = agentFiles.map(function(f) { return readJsonSafe(path.join(agentsDir, f)); }).filter(Boolean);
    var allDone = agents.length > 0 && agents.every(function(a) { return a.status === 'completed' || a.status === 'failed'; });

    if (allDone) {
      var finishedAt = 0;
      for (var j = 0; j < agents.length; j++) {
        var t = agents[j].finished ? new Date(agents[j].finished).getTime() : 0;
        if (t > finishedAt) finishedAt = t;
      }
      if (finishedAt > 0 && (now - finishedAt) >= archiveDelay) {
        meta.archivedAt = new Date().toISOString();
        try { fs.writeFileSync(path.join(runDir, 'meta.json'), JSON.stringify(meta)); }
        catch (e) { /* skip */ }
      }
    }
  }

  // Purge expired archived runs (delete from disk after TTL)
  if (purgeTtl > 0) {
    try { entries = fs.readdirSync(RUNS_DIR, { withFileTypes: true }); }
    catch (e) { entries = []; }

    for (var k = 0; k < entries.length; k++) {
      var pentry = entries[k];
      if (!pentry.isDirectory() || pentry.name === '.archive') continue;
      var pmeta = readJsonSafe(path.join(RUNS_DIR, pentry.name, 'meta.json')) || {};
      if (!pmeta.archivedAt) continue;
      var archivedAt = new Date(pmeta.archivedAt).getTime();
      if (archivedAt > 0 && (now - archivedAt) >= purgeTtl) {
        try { fs.rmSync(path.join(RUNS_DIR, pentry.name), { recursive: true }); }
        catch (e) { /* skip */ }
      }
    }
  }
}

// Run archive/purge every 30 seconds
setInterval(archiveAndPurge, 30000);

// -- Data reading: agent runs --

function readJsonSafe(filePath) {
  try {
    var raw = fs.readFileSync(filePath, 'utf8');
    // Normalize Windows backslashes in JSON values before parsing
    // Handles Windows backslash paths that break JSON.parse
    raw = raw.replace(/\\([^"\\\/bfnrtu])/g, '/$1');
    return JSON.parse(raw);
  }
  catch (e) { return null; }
}

function getRuns() {
  var entries;
  try { entries = fs.readdirSync(RUNS_DIR, { withFileTypes: true }); }
  catch (e) { entries = []; }

  var runs = [];
  for (var i = 0; i < entries.length; i++) {
    var entry = entries[i];
    if (!entry.isDirectory() || entry.name === '.archive') continue;

    var runDir = path.join(RUNS_DIR, entry.name);
    var meta = readJsonSafe(path.join(runDir, 'meta.json')) || {};
    var agentsDir = path.join(runDir, 'agents');

    var agentFiles;
    try { agentFiles = fs.readdirSync(agentsDir).filter(function(f) { return f.endsWith('.json'); }); }
    catch (e) { agentFiles = []; }

    var agents = agentFiles
      .map(function(f) { return readJsonSafe(path.join(agentsDir, f)); })
      .filter(Boolean);

    var hasRunning = agents.some(function(a) { return a.status === 'running'; });
    var hasFailed = agents.some(function(a) { return a.status === 'failed'; });
    var allDone = agents.length > 0 && agents.every(function(a) { return a.status === 'completed' || a.status === 'failed'; });

    runs.push({
      id: entry.name,
      session: meta.session || entry.name.split('--')[0],
      started: meta.started || null,
      archivedAt: meta.archivedAt || null,
      wave: meta.wave || 1,
      status: hasRunning ? 'running' : allDone ? (hasFailed ? 'failed' : 'completed') : 'waiting',
      agents: agents.sort(function(a, b) { return (a.id || '').localeCompare(b.id || ''); })
    });
  }

  var order = { running: 0, waiting: 1, failed: 2, completed: 3 };
  runs.sort(function(a, b) {
    var diff = (order[a.status] || 9) - (order[b.status] || 9);
    if (diff !== 0) return diff;
    return (b.started || '').localeCompare(a.started || '');
  });

  return runs;
}

function getArchivedRuns() {
  // Archived runs are in the same RUNS_DIR but have archivedAt in meta.json
  var allRuns = getRuns();
  return allRuns.filter(function(r) { return r.archivedAt; });
}

function getActiveRuns() {
  var allRuns = getRuns();
  return allRuns.filter(function(r) { return !r.archivedAt; });
}

// -- Data reading: sessions --

function parseSessionFile(filePath) {
  try {
    var content = fs.readFileSync(filePath, 'utf8');
    var lines = content.split('\n').slice(0, 25);
    var text = lines.join('\n');
    var name = path.basename(filePath, '.md');

    var dateMatch = text.match(/\*\*(?:Checkpointed|Created|Closed|Started):\*\*\s*(.+)/);
    var dateStr = dateMatch ? dateMatch[1].trim() : null;
    var isoMatch = dateStr ? dateStr.match(/(\d{4}-\d{2}-\d{2})/) : null;
    var dateIso = isoMatch ? isoMatch[1] : null;

    var taskMatch = text.match(/## Current Task\n([^\n]+)/);
    var statusMatch = text.match(/\*\*Status:\*\*\s*([^\n]+)/);

    var repos = [];
    var repoIdx = content.indexOf('## Repos Involved');
    if (repoIdx !== -1) {
      var repoLines = content.substring(repoIdx).split('\n').slice(1);
      for (var j = 0; j < repoLines.length; j++) {
        var rl = repoLines[j];
        if (rl.startsWith('- ')) repos.push(rl.substring(2).split(' -- ')[0].trim());
        else if (rl.startsWith('#') || (rl.trim() === '' && repos.length > 0)) break;
      }
    }

    // Map repos to engrams
    var engrams = [];
    var engramDir = path.join(DATA_DIR, '..', 'engrams');
    for (var ri = 0; ri < repos.length; ri++) {
      var repoPath = repos[ri].replace(/\\/g, '/');
      var repoName = repoPath.split('/').filter(Boolean).pop() || '';
      if (!repoName) continue;
      // Check for exact match and common patterns
      var candidates = [
        repoName.toLowerCase() + '-context.md',
        repoName.toLowerCase().replace(/-/g, '') + '-context.md'
      ];
      for (var ci = 0; ci < candidates.length; ci++) {
        try {
          if (fs.existsSync(path.join(engramDir, candidates[ci]))) {
            engrams.push(candidates[ci].replace('-context.md', ''));
            break;
          }
        } catch (e) {}
      }
    }

    // Also check for Active Bundles section
    var bundles = [];
    var bundleIdx = content.indexOf('## Active Bundles');
    if (bundleIdx !== -1) {
      var bundleLines = content.substring(bundleIdx).split('\n').slice(1);
      for (var bi = 0; bi < bundleLines.length; bi++) {
        var bl = bundleLines[bi];
        if (bl.startsWith('- ')) {
          var bname = bl.substring(2).split(' -- ')[0].trim().replace(/\.md$/, '');
          if (bname && bname !== '(none yet)' && bname.toLowerCase() !== 'none') bundles.push(bname);
        }
        else if (bl.startsWith('#') || (bl.trim() === '' && bundles.length > 0)) break;
      }
    }

    return {
      name: name,
      date: dateStr,
      dateIso: dateIso,
      task: taskMatch ? taskMatch[1].trim() : null,
      status: statusMatch ? statusMatch[1].trim() : null,
      repos: repos,
      engrams: engrams,
      bundles: bundles,
      file: filePath
    };
  } catch (e) {
    return null;
  }
}

function getSessions() {
  var sessions = [];
  var files;
  try { files = fs.readdirSync(SESSIONS_DIR); }
  catch (e) { return sessions; }

  for (var i = 0; i < files.length; i++) {
    var f = files[i];
    if (!f.endsWith('.md')) continue;
    if (f === 'README.md' || f.startsWith('_') || f.startsWith('.')) continue;
    var fullPath = path.join(SESSIONS_DIR, f);
    var stat;
    try { stat = fs.statSync(fullPath); } catch (e) { continue; }
    if (!stat.isFile()) continue;
    var session = parseSessionFile(fullPath);
    if (session) {
      // Use file mtime as the authoritative last-updated timestamp
      session.mtime = stat.mtime.toISOString();
      if (!session.dateIso || session.dateIso.length <= 10) {
        session.dateIso = session.mtime;
      }
      sessions.push(session);
    }
  }

  // Sort by mtime descending (most recently updated first)
  sessions.sort(function(a, b) {
    return (b.mtime || b.dateIso || '').localeCompare(a.mtime || a.dateIso || '');
  });

  return sessions;
}

function getSessionContent(name) {
  var filePath = path.join(SESSIONS_DIR, name + '.md');
  try { return fs.readFileSync(filePath, 'utf8'); }
  catch (e) { return null; }
}

// -- Settings --

var DEFAULT_SETTINGS = {
  dashboard: { reporting: true, pollingMs: 2000 }
};

function getSettings() {
  var saved = readJsonSafe(SETTINGS_FILE);
  if (!saved) return DEFAULT_SETTINGS;
  return {
    dashboard: Object.assign({}, DEFAULT_SETTINGS.dashboard, saved.dashboard)
  };
}

function saveSettings(data) {
  try {
    fs.writeFileSync(SETTINGS_FILE, JSON.stringify(data, null, 2) + '\n', 'utf8');
    return true;
  } catch (e) { return false; }
}

function readBody(req, cb) {
  var body = '';
  req.on('data', function(chunk) { body += chunk; });
  req.on('end', function() { cb(body); });
}

// -- Browser auto-open --

function openBrowser(url) {
  var cmd = process.platform === 'win32' ? 'cmd /c start "" "' + url + '"'
          : process.platform === 'darwin' ? 'open "' + url + '"'
          : 'xdg-open "' + url + '"';
  exec(cmd, function() {});
}

// -- HTTP server --

var server = http.createServer(function(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  if (req.url === '/' || req.url === '/index.html') {
    try {
      var html = fs.readFileSync(HTML_FILE, 'utf8');
      res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
      res.end(html);
    } catch (e) {
      res.writeHead(500, { 'Content-Type': 'text/plain' });
      res.end('Dashboard HTML not found at: ' + HTML_FILE);
    }
    return;
  }

  if (req.url === '/api/settings' && req.method === 'GET') {
    res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
    res.end(JSON.stringify(getSettings()));
    return;
  }

  if (req.url === '/api/settings' && req.method === 'POST') {
    readBody(req, function(body) {
      try {
        var data = JSON.parse(body);
        if (saveSettings(data)) {
          res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
          res.end(JSON.stringify(getSettings()));
        } else {
          res.writeHead(500, { 'Content-Type': 'text/plain' });
          res.end('Failed to write settings');
        }
      } catch (e) {
        res.writeHead(400, { 'Content-Type': 'text/plain' });
        res.end('Invalid JSON');
      }
    });
    return;
  }

  if (req.url === '/api/status') {
    // Determine which sessions are active by reading heartbeats/ directory
    // Each file: filename = Claude session ID, content = JitNeuro session name, mtime = last heartbeat
    var activeInstances = {}; // sessionName -> { lastSeen: ISO, instanceCount: N }
    try {
      var hbDir = path.join(SESSIONS_DIR, 'heartbeats');
      var hbFiles = fs.readdirSync(hbDir);
      for (var hi = 0; hi < hbFiles.length; hi++) {
        try {
          var hbPath = path.join(hbDir, hbFiles[hi]);
          var hbStat = fs.statSync(hbPath);
          if (!hbStat.isFile()) continue;
          var hbName = fs.readFileSync(hbPath, 'utf8').trim();
          if (!hbName) continue;
          var hbMtime = hbStat.mtime.toISOString();
          var hbAgeMs = Date.now() - hbStat.mtime.getTime();
          if (hbAgeMs < 300000) { // active if heartbeat within 5 minutes
            if (!activeInstances[hbName]) activeInstances[hbName] = { lastSeen: hbMtime, instanceCount: 0 };
            activeInstances[hbName].instanceCount++;
            if (hbMtime > activeInstances[hbName].lastSeen) activeInstances[hbName].lastSeen = hbMtime;
          }
        } catch (e) {}
      }
    } catch (e) {}

    // Build hierarchical view: sessions with nested agent runs
    var allSessions = getSessions();
    // Include ALL runs (active + recently archived) for session grouping
    var allRuns = getRuns();
    var allArchived = allRuns.filter(function(r) { return r.archivedAt; });

    // Tag sessions with active status and heartbeat mtime
    for (var ai = 0; ai < allSessions.length; ai++) {
      var sName = allSessions[ai].name;
      var inst = activeInstances[sName];
      allSessions[ai].isActive = !!inst;
      if (inst) {
        allSessions[ai].lastHeartbeat = inst.lastSeen;
        allSessions[ai].instanceCount = inst.instanceCount;
        // Use heartbeat as mtime if newer than file mtime
        if (inst.lastSeen > (allSessions[ai].mtime || '')) {
          allSessions[ai].mtime = inst.lastSeen;
        }
      }
    }

    // Group runs by session name
    var runsBySession = {};
    for (var ri = 0; ri < allRuns.length; ri++) {
      var sn = allRuns[ri].session || 'unknown';
      if (!runsBySession[sn]) runsBySession[sn] = [];
      runsBySession[sn].push(allRuns[ri]);
    }

    // Attach runs to matching sessions
    for (var si = 0; si < allSessions.length; si++) {
      allSessions[si].agents = runsBySession[allSessions[si].name] || [];
      delete runsBySession[allSessions[si].name];
    }

    // Orphaned runs (session name doesn't match any session file)
    var orphanedRuns = [];
    for (var key in runsBySession) {
      for (var oi = 0; oi < runsBySession[key].length; oi++) {
        orphanedRuns.push(runsBySession[key][oi]);
      }
    }

    var status = {
      timestamp: new Date().toISOString(),
      sessions: allSessions,
      orphanedRuns: orphanedRuns,
      archivedRuns: allArchived,
      runs: allRuns,
      settings: getSettings(),
      config: { dataDir: DATA_DIR, sessionsDir: SESSIONS_DIR, settingsFile: SETTINGS_FILE }
    };
    res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
    res.end(JSON.stringify(status));
    return;
  }

  // /api/sessions/{name} -- return full markdown content
  var sessionMatch = req.url.match(/^\/api\/sessions\/([^/]+)$/);
  if (sessionMatch) {
    var sessionName = decodeURIComponent(sessionMatch[1]);
    var content = getSessionContent(sessionName);
    if (content) {
      res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end(content);
    } else {
      res.writeHead(404, { 'Content-Type': 'text/plain' });
      res.end('Session not found: ' + sessionName);
    }
    return;
  }

  // /session/{name} -- standalone session detail page
  var sessionPageMatch = req.url.match(/^\/session\/([^/]+)$/);
  if (sessionPageMatch) {
    var sName = decodeURIComponent(sessionPageMatch[1]);
    var sContent = getSessionContent(sName);
    if (!sContent) {
      res.writeHead(404, { 'Content-Type': 'text/plain' });
      res.end('Session not found: ' + sName);
      return;
    }
    var sHtml = '<!DOCTYPE html><html><head><meta charset="utf-8">';
    sHtml += '<title>Session: ' + sName + '</title>';
    sHtml += '<style>';
    sHtml += 'body { background: #0d1117; color: #c9d1d9; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif; padding: 24px 40px; max-width: 900px; margin: 0 auto; }';
    sHtml += 'h1 { color: #f0f6fc; font-size: 20px; border-bottom: 1px solid #21262d; padding-bottom: 12px; }';
    sHtml += 'pre { white-space: pre-wrap; word-wrap: break-word; font-size: 13px; line-height: 1.6; color: #c9d1d9; }';
    sHtml += '.toolbar { display: flex; gap: 12px; margin-bottom: 16px; }';
    sHtml += '.btn { background: #21262d; color: #c9d1d9; border: 1px solid #30363d; padding: 6px 14px; border-radius: 6px; cursor: pointer; font-size: 12px; text-decoration: none; }';
    sHtml += '.btn:hover { background: #30363d; color: #f0f6fc; }';
    sHtml += '.updated { font-size: 11px; color: #6e7681; }';
    sHtml += '</style></head><body>';
    sHtml += '<div class="toolbar">';
    sHtml += '<a class="btn" href="/">Back to Dashboard</a>';
    sHtml += '<a class="btn" href="" onclick="location.reload();return false;">Refresh</a>';
    sHtml += '<span class="updated" id="updated">Loaded: ' + new Date().toLocaleString() + '</span>';
    sHtml += '</div>';
    sHtml += '<h1>Session: ' + sName.replace(/</g, '&lt;') + '</h1>';
    sHtml += '<pre id="content">' + sContent.replace(/&/g, '&amp;').replace(/</g, '&lt;') + '</pre>';
    sHtml += '<script>';
    sHtml += 'setInterval(function(){';
    sHtml += '  fetch("/api/sessions/' + encodeURIComponent(sName) + '")';
    sHtml += '    .then(function(r){return r.ok?r.text():null})';
    sHtml += '    .then(function(t){';
    sHtml += '      if(t!==null){';
    sHtml += '        var el=document.getElementById("content");';
    sHtml += '        var escaped=t.replace(/&/g,"&amp;").replace(/</g,"&lt;");';
    sHtml += '        if(el.innerHTML!==escaped){el.innerHTML=escaped;document.getElementById("updated").textContent="Updated: "+new Date().toLocaleString()}';
    sHtml += '      }';
    sHtml += '    }).catch(function(){});';
    sHtml += '}, 5000);';
    sHtml += '</script>';
    sHtml += '</body></html>';
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
    res.end(sHtml);
    return;
  }

  res.writeHead(404, { 'Content-Type': 'text/plain' });
  res.end('Not found');
});

server.listen(PORT, function() {
  var url = 'http://localhost:' + PORT;
  console.log('');
  console.log('  JitNeuro Agent Dashboard');
  console.log('  URL:        ' + url);
  console.log('  Runs:       ' + RUNS_DIR);
  console.log('  Sessions:   ' + SESSIONS_DIR);
  console.log('  Settings:   ' + SETTINGS_FILE);
  console.log('  Press Ctrl+C to stop.');
  console.log('');
  if (!NO_OPEN) openBrowser(url);
});

server.on('error', function(err) {
  if (err.code === 'EADDRINUSE') {
    var url = 'http://localhost:' + PORT;
    var probe = http.get(url + '/api/status', function(res) {
      if (res.statusCode === 200) {
        console.log('Dashboard already running at ' + url + ' -- opening browser.');
        openBrowser(url);
        setTimeout(function() { process.exit(0); }, 500);
      } else {
        console.error('Port ' + PORT + ' is in use by another service. Use --port=XXXX');
        process.exit(1);
      }
    });
    probe.on('error', function() {
      console.error('Port ' + PORT + ' is in use and not responding. Use --port=XXXX');
      process.exit(1);
    });
    probe.setTimeout(2000, function() {
      console.error('Port ' + PORT + ' timed out. Use --port=XXXX');
      process.exit(1);
    });
    return;
  }
  console.error(err.message);
  process.exit(1);
});

process.on('SIGINT', function() {
  console.log('\nDashboard stopped.');
  server.close();
  process.exit(0);
});

process.on('SIGTERM', function() {
  server.close();
  process.exit(0);
});
