'use strict';

/*
 * Mock Rockstar "Social Hub" API.
 *
 * Deliberately UN-optimised for the "Surviving Launch Day" session:
 *   - Single Node.js process (no clustering / worker threads).
 *   - /api/v1/auth runs a heavy SYNCHRONOUS password hash that blocks the
 *     event loop. Under a few hundred concurrent players this starves every
 *     other request, so the single Mission 1 VM tips over into timeouts / 504s.
 *
 * The fix in Mission 3 is infrastructure, not code: put two of these VMs
 * behind an Azure Load Balancer so the work is spread across more CPUs.
 */

const crypto = require('crypto');
const express = require('express');

const app = express();
const PORT = process.env.PORT || 80;
const HOSTNAME = require('os').hostname();

// How expensive the auth hash is. Higher = the single VM crashes sooner.
// Overridable via env so instructors can tune the drama.
const HASH_ITERATIONS = parseInt(process.env.HASH_ITERATIONS || '150000', 10);

app.use(express.json());

// Cheap liveness check used by the Azure Load Balancer health probe.
app.get('/api/v1/health', (req, res) => {
  res.json({ status: 'ok', host: HOSTNAME });
});

// Expensive on purpose: blocks the event loop while "verifying credentials".
app.post('/api/v1/auth', (req, res) => {
  const username = (req.body && req.body.username) || 'anon';
  // Synchronous PBKDF2 == CPU-bound work on the main thread.
  const hash = crypto
    .pbkdf2Sync(username, 'rockstar-salt', HASH_ITERATIONS, 64, 'sha512')
    .toString('hex');
  res.json({
    token: hash.slice(0, 32),
    username,
    host: HOSTNAME,
  });
});

// Lighter read path: a tiny, fixed player profile.
app.get('/api/v1/profile', (req, res) => {
  res.json({
    id: req.query.id || '00000000',
    handle: 'LuciaCaminos',
    city: 'Vice City',
    level: 6,
    host: HOSTNAME,
  });
});

app.get('/', (req, res) => {
  res.json({ service: 'rockstar-social-hub', host: HOSTNAME });
});

app.listen(PORT, () => {
  console.log(`Social Hub listening on :${PORT} (host ${HOSTNAME})`);
});
