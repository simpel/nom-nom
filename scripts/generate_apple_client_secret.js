#!/usr/bin/env node

/**
 * Generates an Apple OAuth client_secret JWT for Supabase Auth using the .p8 private key.
 *
 * Usage:
 *   node scripts/generate_apple_client_secret.js
 */

const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const TEAM_ID = 'D4F66LSYSF';
const KEY_ID = '6FLDB732GY';
const CLIENT_ID = 'se.joelsanden.nomnom';
const P8_PATH = path.resolve(__dirname, '..', 'AuthKey_6FLDB732GY.p8');

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
