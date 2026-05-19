#!/usr/bin/env node
// Native Messaging Host for Worship YT Player.
// Protocol: Chrome/Edge writes 4-byte little-endian length prefix, then UTF-8 JSON.
// We respond with the same framing.

const fs = require('fs');
const path = require('path');
const os = require('os');

const LOG_PATH = path.join(os.homedir(), '.worship-player-host.log');
function log(...args) {
  const line = `[${new Date().toISOString()}] ${args.map(a => typeof a === 'string' ? a : JSON.stringify(a)).join(' ')}\n`;
  try { fs.appendFileSync(LOG_PATH, line); } catch {}
}

function sendMessage(obj) {
  const json = Buffer.from(JSON.stringify(obj), 'utf8');
  const header = Buffer.alloc(4);
  header.writeUInt32LE(json.length, 0);
  process.stdout.write(Buffer.concat([header, json]));
}

// --- Incoming message parser (handles partial reads) ------------------------
let buffer = Buffer.alloc(0);
process.stdin.on('data', chunk => {
  buffer = Buffer.concat([buffer, chunk]);
  while (buffer.length >= 4) {
    const len = buffer.readUInt32LE(0);
    if (buffer.length < 4 + len) break;
    const body = buffer.subarray(4, 4 + len);
    buffer = buffer.subarray(4 + len);
    let msg;
    try {
      msg = JSON.parse(body.toString('utf8'));
    } catch (e) {
      log('parse error', e.message);
      continue;
    }
    handleMessage(msg);
  }
});

process.stdin.on('end', () => {
  log('stdin end, exiting');
  process.exit(0);
});

// --- Handlers ---------------------------------------------------------------
function handleMessage(msg) {
  log('recv', msg);
  const { id, type } = msg || {};
  try {
    switch (type) {
      case 'ping':
        sendMessage({ id, ok: true, type: 'pong', pid: process.pid, time: Date.now() });
        break;
      case 'env':
        sendMessage({
          id, ok: true,
          platform: process.platform,
          arch: process.arch,
          node: process.version,
          binDir: path.join(__dirname, '..', 'bin', `${process.platform === 'win32' ? 'win-x64' : process.platform === 'darwin' ? `darwin-${process.arch}` : `${process.platform}-${process.arch}`}`),
        });
        break;
      default:
        sendMessage({ id, ok: false, error: `unknown type: ${type}` });
    }
  } catch (e) {
    log('handler error', e.stack);
    sendMessage({ id, ok: false, error: e.message });
  }
}

log('host started, pid', process.pid);
