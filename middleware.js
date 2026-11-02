import { next, rewrite } from "@vercel/functions";
import { createHmac, timingSafeEqual } from "node:crypto";

const COOKIE = "bf_access";

const NO_STORE = {
  "cache-control": "private, no-store, max-age=0",
  "referrer-policy": "no-referrer",
  "x-robots-tag": "noindex, nofollow",
};

function token() {
  const secret = process.env.SITE_SECRET;
  if (!secret) return null;
  return createHmac("sha256", secret).update("unlocked").digest("hex");
}

function unlocked(request) {
  const expected = token();
  if (!expected) return false;

  const cookie = request.headers.get("cookie") || "";
  const part = cookie
    .split(";")
    .map((item) => item.trim())
    .find((item) => item.startsWith(COOKIE + "="));

  if (!part) return false;

  const given = Buffer.from(part.slice(COOKIE.length + 1));
  const wanted = Buffer.from(expected);

  return given.length === wanted.length && timingSafeEqual(given, wanted);
}

export const config = {
  matcher: "/((?!unlock\\.html|api/unlock).*)",
};

export default function middleware(request) {
  if (unlocked(request)) return next({ headers: NO_STORE });
  return rewrite(new URL("/unlock.html", request.url), { headers: NO_STORE });
}
