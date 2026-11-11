// Sends Nosiva's push notifications through Firebase Cloud Messaging.
//
// The database decides who is notified about what (migration 0026) and
// leaves each notification in private.push_outbox. This function sends
// what's waiting, in each phone's language, then removes it:
//   * POST /flush from the app, right after every action that notifies
//     someone (needs the person's sign-in token), so notifications arrive
//     within a second or two;
//   * the hourly `pushHourly` schedule (neon.ts), in case a nudge was
//     missed. Deliberately rare: each run wakes the database.
//
// Secret (function env, set at deploy time from neon/.env.secrets):
//   FCM_SERVICE_ACCOUNT  the Firebase service-account key, as one line of JSON
import { db, fromNeonSchedule, json, signedInUser } from "./lib/common";

type Locale = "en" | "mk";

interface PushEvent {
  kind: string;
  actor_name?: string | null;
  listing_title?: string | null;
  preview?: string | null;
  has_image?: boolean;
  amount?: number | null;
  conversation_id?: string | null;
  order_id?: string | null;
  rating?: number | null;
  user_id?: string | null;
}

interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
}

/** Where tapping the notification takes the person, read by the app. */
type Target = Record<string, string>;

const BATCH = 50;
const MAX_ATTEMPTS = 5;

let lastFlush = 0;

export default {
  async fetch(request: Request): Promise<Response> {
    if (request.method !== "POST") return json({ error: "Use POST" }, 405);
    if (new URL(request.url).pathname !== "/flush") return json({ error: "Not found" }, 404);
    if (!fromNeonSchedule(request) && !(await signedInUser(request))) {
      return json({ error: "Sign in required" }, 401);
    }
    // Many phones may nudge at once; one pass every half second is plenty.
    if (Date.now() - lastFlush < 500) return json({ skipped: true });
    lastFlush = Date.now();

    try {
      return json(await flush());
    } catch (e) {
      console.error("push flush failed", e);
      return json({ error: "Something went wrong" }, 500);
    }
  },
};

async function flush(): Promise<{ sent: number; failed: number }> {
  const pool = db();
  // Old or repeatedly failing notifications are no longer useful.
  await pool.query(
    `delete from private.push_outbox
      where created_at < now() - interval '1 day' or attempts >= $1`,
    [MAX_ATTEMPTS],
  );
  // Claim a batch: removed from the outbox as it's read, so two flushes at
  // once never send the same notification twice.
  const { rows } = await pool.query(
    `delete from private.push_outbox
      where id in (
        select id from private.push_outbox
         order by id
         limit $1
         for update skip locked)
      returning id, recipient, payload, attempts, created_at`,
    [BATCH],
  );
  if (rows.length === 0) return { sent: 0, failed: 0 };

  const account = serviceAccount();
  let accessToken: string | null = null;
  try {
    if (account) accessToken = await googleAccessToken(account);
  } catch (e) {
    console.error("Google sign-in for Firebase failed", e);
  }
  if (!account || !accessToken) {
    await requeue(rows);
    return { sent: 0, failed: rows.length };
  }

  const recipients = [...new Set(rows.map((r) => r.recipient as string))];
  const tokens = await pool.query(
    `select token, user_id, locale from public.push_tokens where user_id = any($1::uuid[])`,
    [recipients],
  );

  let sent = 0;
  let failed = 0;
  const dead: string[] = [];
  for (const row of rows) {
    const event = row.payload as PushEvent;
    const target = targetFor(event);
    if (!target) continue;
    const phones = tokens.rows.filter((t) => t.user_id === row.recipient).slice(0, 10);
    await Promise.all(phones.map(async ({ token, locale }) => {
      const text = textFor(event, locale === "mk" ? "mk" : "en");
      if (!text) return;
      const res = await fetch(
        `https://fcm.googleapis.com/v1/projects/${account.project_id}/messages:send`,
        {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            message: {
              token,
              notification: { title: text.title, body: text.body },
              data: { kind: event.kind, ...target },
              android: {
                priority: "HIGH",
                notification: {
                  channel_id: "nosiva_activity",
                  icon: "ic_notification",
                  color: "#C2748C",
                  // A newer message from the same chat replaces the older one.
                  tag: event.conversation_id ? `chat-${event.conversation_id}` : undefined,
                },
              },
            },
          }),
        },
      );
      if (res.ok) {
        sent++;
      } else {
        failed++;
        // The app was removed from that phone: forget the address.
        if (res.status === 404) dead.push(token);
      }
      await res.body?.cancel();
    }));
  }
  if (dead.length) {
    await pool.query(`delete from public.push_tokens where token = any($1::text[])`, [dead]);
  }
  return { sent, failed };
}

async function requeue(rows: { recipient: string; payload: unknown; attempts: number; created_at: Date }[]) {
  for (const r of rows) {
    await db().query(
      `insert into private.push_outbox (recipient, payload, attempts, created_at)
       values ($1, $2, $3, $4)`,
      [r.recipient, r.payload, r.attempts + 1, r.created_at],
    );
  }
}

// ---------------------------------------------------------------------------
// Text
// ---------------------------------------------------------------------------

function textFor(e: PushEvent, l: Locale): { title: string; body: string } | null {
  const mk = l === "mk";
  const who = clip(e.actor_name, 40) || (mk ? "Некој" : "Someone");
  const item = clip(e.listing_title, 60);
  const quoted = mk ? `„${item}“` : `“${item}”`;
  const price = formatPrice(e.amount);

  switch (e.kind) {
    case "message": {
      const preview = clip(e.preview, 120);
      return {
        title: who,
        body: preview ||
          (e.has_image
            ? (mk ? "Испрати фотографија" : "Sent a photo")
            : (mk ? "Нова порака" : "New message")),
      };
    }
    case "offer_new":
      return mk
        ? { title: "Нова понуда", body: `${who} понуди ${price} за ${quoted}.` }
        : { title: "New offer", body: `${who} offered ${price} for ${quoted}.` };
    case "offer_accepted":
      return mk
        ? {
          title: "Понудата е прифатена",
          body: `${who} ја прифати твојата понуда за ${quoted}. Плати во готово на курирот при достава.`,
        }
        : {
          title: "Offer accepted",
          body: `${who} accepted your offer for ${quoted}. Pay the courier in cash on delivery.`,
        };
    case "offer_declined":
      return mk
        ? { title: "Понудата е одбиена", body: `Твојата понуда за ${quoted} е одбиена.` }
        : { title: "Offer declined", body: `Your offer for ${quoted} was declined.` };
    case "order_new":
      return mk
        ? { title: "Нова нарачка", body: `${who} нарача ${quoted} за ${price}.` }
        : { title: "New order", body: `${who} ordered ${quoted} for ${price}.` };
    case "order_paid":
      return mk
        ? { title: "Нарачката е прифатена", body: `${who} ја прифати твојата нарачка за ${quoted}.` }
        : { title: "Order accepted", body: `${who} accepted your order for ${quoted}.` };
    case "order_shipped":
      return mk
        ? {
          title: "Твојата нарачка е на пат",
          body: `${quoted} е испратена. Подготви ${price} во готово за курирот.`,
        }
        : {
          title: "Your order is on its way",
          body: `${quoted} has been sent. Have ${price} in cash ready for the courier.`,
        };
    case "order_delivered":
      return mk
        ? { title: "Нарачката е доставена", body: `${quoted} е означена како доставена.` }
        : { title: "Order delivered", body: `${quoted} was marked as delivered.` };
    case "order_cancelled":
      return mk
        ? { title: "Нарачката е откажана", body: `${who} ја откажа нарачката за ${quoted}.` }
        : { title: "Order cancelled", body: `${who} cancelled the order for ${quoted}.` };
    case "review_new": {
      const stars = Math.min(5, Math.max(1, Math.round(Number(e.rating) || 0)));
      return mk
        ? {
          title: "Нова оценка",
          body: `${who} ти остави оценка од ${stars} ${stars === 1 ? "ѕвезда" : "ѕвезди"}.`,
        }
        : { title: "New review", body: `${who} left you a ${stars}-star review.` };
    }
    case "follow_new":
      return mk
        ? { title: "Нов следбеник", body: `${who} почна да те следи.` }
        : { title: "New follower", body: `${who} started following you.` };
    default:
      return null;
  }
}

/** Same format as the app: "1.200 ден". */
function formatPrice(amount: number | null | undefined): string {
  const n = Math.round(Number(amount) || 0);
  return `${String(n).replace(/\B(?=(\d{3})+(?!\d))/g, ".")} ден`;
}

function clip(value: string | null | undefined, max: number): string {
  const text = (value ?? "").replace(/\s+/g, " ").trim();
  return text.length > max ? `${text.slice(0, max - 1)}…` : text;
}

const uuid = /^[0-9a-f-]{36}$/i;

function targetFor(e: PushEvent): Target | null {
  if (e.kind === "message") {
    return uuid.test(e.conversation_id ?? "")
      ? { target: "chat", id: e.conversation_id! }
      : null;
  }
  if (e.kind.startsWith("order_") || (e.kind === "offer_accepted" && e.order_id)) {
    return uuid.test(e.order_id ?? "") ? { target: "order", id: e.order_id! } : null;
  }
  // Your reviews; the new follower's profile.
  if (e.kind === "review_new") {
    return uuid.test(e.user_id ?? "") ? { target: "reviews", id: e.user_id! } : null;
  }
  if (e.kind === "follow_new") {
    return uuid.test(e.user_id ?? "") ? { target: "user", id: e.user_id! } : null;
  }
  // Offers live in Activity: the seller's under Selling, the buyer's under
  // Buying.
  if (e.kind === "offer_new") return { target: "activity", tab: "selling" };
  if (e.kind === "offer_accepted" || e.kind === "offer_declined") {
    return { target: "activity", tab: "buying" };
  }
  return null;
}

// ---------------------------------------------------------------------------
// Google sign-in for Firebase (service account -> short-lived access token)
// ---------------------------------------------------------------------------

function serviceAccount(): ServiceAccount | null {
  try {
    const parsed = JSON.parse(process.env.FCM_SERVICE_ACCOUNT ?? "");
    if (parsed?.project_id && parsed?.client_email && parsed?.private_key) {
      return parsed;
    }
  } catch {
    // fall through
  }
  return null;
}

let cachedToken: { value: string; expires: number } | null = null;

async function googleAccessToken(account: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedToken && cachedToken.expires - 60 > now) return cachedToken.value;

  const header = { alg: "RS256", typ: "JWT" };
  const claims = {
    iss: account.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };
  const unsigned = `${base64url(JSON.stringify(header))}.${base64url(JSON.stringify(claims))}`;
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToDer(account.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = new Uint8Array(
    await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(unsigned)),
  );
  const assertion = `${unsigned}.${base64url(signature)}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  if (!res.ok) throw new Error(`Google token request failed: ${res.status}`);
  const body = await res.json();
  cachedToken = { value: body.access_token, expires: now + (body.expires_in ?? 3600) };
  return cachedToken.value;
}

function pemToDer(pem: string): ArrayBuffer {
  const b64 = pem.replace(/-----[^-]+-----/g, "").replace(/\s+/g, "");
  const bin = atob(b64);
  const bytes = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
  return bytes.buffer;
}

function base64url(input: string | Uint8Array): string {
  const bytes = typeof input === "string" ? new TextEncoder().encode(input) : input;
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}
