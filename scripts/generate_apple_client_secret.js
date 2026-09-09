#!/usr/bin/env node

/**
 * Generates an Apple OAuth client_secret JWT for Supabase Auth (the value that
 * goes in SUPABASE_AUTH_EXTERNAL_APPLE_SECRET). This is signed with the
 * "Sign in with Apple" key — a different key from the APNs one. Keep them
 * separate so a leak of either never forces you to rotate both.
 *
 * Usage:
 *   APPLE_SIWA_KEY_ID=XXXXXXXXXX node scripts/generate_apple_client_secret.js
 *
 * Defaults: KEY_PATH is keys/signinwithapple/AuthKey_<KEY_ID>.p8. Override with
 * APPLE_SIWA_KEY_PATH (relative to the repo root). The keys/ directory is
 * gitignored — never commit a .p8.
 */

const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const TEAM_ID = process.env.APPLE_TEAM_ID || 'D4F66LSYSF';
const CLIENT_ID = process.env.APPLE_SIWA_CLIENT_ID || 'se.joelsanden.nomnom';
const KEY_ID = process.env.APPLE_SIWA_KEY_ID;

if (!KEY_ID) {
  console.error('❌ Set APPLE_SIWA_KEY_ID to the Key ID of your Sign in with Apple key.');
  process.exit(1);
}

const P8_PATH = path.resolve(
  __dirname,
  '..',
  process.env.APPLE_SIWA_KEY_PATH || `keys/signinwithapple/AuthKey_${KEY_ID}.p8`,
);

if (!fs.existsSync(P8_PATH)) {
  console.error(`❌ Could not find .p8 file at: ${P8_PATH}`);
  process.exit(1);
}

const privateKey = fs.readFileSync(P8_PATH, 'utf8');

const header = {
  alg: 'ES256',
  kid: KEY_ID,
  typ: 'JWT'
};

const now = Math.floor(Date.now() / 1000);
// 180 days (Apple allows max 6 months)
const exp = now + 180 * 24 * 60 * 60;

const payload = {
  iss: TEAM_ID,
  iat: now,
  exp: exp,
  aud: 'https://appleid.apple.com',
  sub: CLIENT_ID
};

function base64url(data) {
  const buf = Buffer.isBuffer(data) ? data : Buffer.from(typeof data === 'string' ? data : JSON.stringify(data));
  return buf.toString('base64').replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
}

const headerB64 = base64url(header);
const payloadB64 = base64url(payload);
const signInput = `${headerB64}.${payloadB64}`;

const sign = crypto.createSign('SHA256');
sign.update(signInput);
sign.end();

const signature = sign.sign({
  key: privateKey,
  dsaEncoding: 'ieee-p1363'
});

const signatureB64 = base64url(signature);
const jwt = `${signInput}.${signatureB64}`;

console.log('\n--- Apple Client Secret (JWT) for Supabase ---');
console.log(jwt);
console.log('----------------------------------------------\n');
console.log(`Expires: ${new Date(exp * 1000).toISOString()} (regenerate before then)\n`);
