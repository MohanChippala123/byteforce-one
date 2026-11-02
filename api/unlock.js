import { createHmac, timingSafeEqual } from "node:crypto";

const COOKIE = "bf_access";
const WINDOW = 10 * 60 * 1000;
const MAX_FAILS = 5;
const attempts = new Map();

function token(secret) {
  return createHmac("sha256", secret).update("unlocked").digest("hex");
}

const wait = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

function clientIp(req) {
  const real = String(req.headers["x-real-ip"] || "").trim();
  if (real) return real;
  const forwarded = String(req.headers["x-forwarded-for"] || "").split(",");
  return (forwarded[forwarded.length - 1] || "").trim() || "unknown";
}

function tooMany(ip) {
  const record = attempts.get(ip);
  if (!record) return 0;
  const age = Date.now() - record.start;
  if (age > WINDOW) return 0;
  if (record.count < MAX_FAILS) return 0;
  return Math.ceil((WINDOW - age) / 1000);
}

function recordFail(ip) {
  const now = Date.now();
  const record = attempts.get(ip);
  if (!record || now - record.start > WINDOW) {
    attempts.set(ip, { start: now, count: 1 });
  } else {
    record.count += 1;
  }
  if (attempts.size > 5000) {
    for (const [key, value] of attempts) {
      if (now - value.start > WINDOW) attempts.delete(key);
    }
  }
  return attempts.get(ip).count;
}

async function readBody(req) {
  if (req.body && typeof req.body === "object") return req.body;
  if (typeof req.body === "string") {
    try {
      return JSON.parse(req.body);
    } catch {
      return {};
    }
  }
  let raw = "";
  try {
    for await (const chunk of req) {
      raw += chunk;
      if (raw.length > 2048) break;
    }
  } catch {
    return {};
  }
  try {
    return JSON.parse(raw);
  } catch {
    return {};
  }
}

function sameCode(given, expected) {
  const a = Buffer.from(given);
  const b = Buffer.from(expected);
  return a.length === b.length && timingSafeEqual(a, b);
}

export default async function handler(req, res) {
  res.setHeader("cache-control", "private, no-store");
  res.setHeader("referrer-policy", "no-referrer");

  if (req.method !== "POST") {
    res.statusCode = 405;
    res.setHeader("allow", "POST");
    res.end("Method not allowed");
    return;
  }

  const expected = String(process.env.SITE_CODE || "").trim();
  const secret = String(process.env.SITE_SECRET || "").trim();

  if (!expected || !secret) {
    res.statusCode = 500;
    res.setHeader("content-type", "application/json");
    res.end(JSON.stringify({ ok: false }));
    return;
  }

  const ip = clientIp(req);
  const retry = tooMany(ip);
  if (retry) {
    res.statusCode = 429;
    res.setHeader("retry-after", String(retry));
    res.setHeader("content-type", "application/json");
    res.end(JSON.stringify({ ok: false }));
    return;
  }

  const body = await readBody(req);
  const code = String((body && body.code) || "").trim();

  if (!code || !sameCode(code, expected)) {
    const attemptsUsed = recordFail(ip);
    await wait(500);
    res.statusCode = 401;
    res.setHeader("content-type", "application/json");
    res.end(JSON.stringify({ ok: false, attempts: attemptsUsed }));
    return;
  }

  attempts.delete(ip);
  res.statusCode = 200;
  res.setHeader(
    "set-cookie",
    `${COOKIE}=${token(secret)}; Path=/; HttpOnly; Secure; SameSite=Lax`,
  );
  res.setHeader("content-type", "application/json");
  res.end(JSON.stringify({ ok: true }));
}
