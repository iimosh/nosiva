// Sends Nosiva's push notifications through Firebase Cloud Messaging.
//
// Called only by the database (see migration 0026: private.queue_push), with
// the shared secret in the `x-push-secret` header. Each call is one event —
// who acted, on what — plus the recipient's phones and their languages; this
// function writes the text in each phone's language and sends it.
//
// Plain web-standard code (fetch + WebCrypto, no libraries, no database
// access), so it runs the same on Supabase Edge Functions or any other
// serverless host.
//
// Secrets (Supabase → Edge Functions → Secrets):
//   FCM_SERVICE_ACCOUNT  the Firebase service-account key file's contents
//   PUSH_WEBHOOK_SECRET  same random value as the Vault secret
//                        push_webhook_secret
//
// Deploy with JWT verification OFF: the database authenticates with the
// shared secret instead.

type Locale = "en" | "mk";

interface PushEvent {
  kind: string;
  tokens: { token: string; locale: string }[];
  actor_name?: string | null;
  listing_title?: string | null;
  preview?: string | null;
  has_image?: boolean;
  amount?: number | null;
  conversation_id?: string | null;
  order_id?: string | null;
}

interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
}

/** Where tapping the notification takes the person, read by the app. */
type Target = Record<string, string>;

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("Method not allowed", { status: 405 });

  const secret = Deno.env.get("PUSH_WEBHOOK_SECRET") ?? "";
  if (!secret || !safeEqual(req.headers.get("x-push-secret") ?? "", secret)) {
    return new Response("Unauthorized", { status: 401 });
  }

  let event: PushEvent;
  try {
    event = await req.json();
  } catch {
    return new Response("Bad request", { status: 400 });
  }

  const tokens = (Array.isArray(event.tokens) ? event.tokens : [])
    .filter((t) => typeof t?.token === "string" && t.token.length >= 20)
    .slice(0, 10);
  if (tokens.length === 0) return json({ sent: 0 });

  const target = targetFor(event);
  if (!target) return new Response("Unknown kind", { status: 400 });

  const account = serviceAccount();
  if (!account) return new Response("Not configured", { status: 500 });
  const accessToken = await googleAccessToken(account);

  let sent = 0;
  const failed: string[] = [];
  await Promise.all(tokens.map(async ({ token, locale }) => {
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
                tag: event.conversation_id
                  ? `chat-${event.conversation_id}`
                  : undefined,
              },
            },
          },
        }),
      },
    );
    if (res.ok) {
      sent++;
    } else {
      failed.push(`${res.status}`);
      await res.body?.cancel();
    }
  }));

  return json({ sent, failed });
});

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
          body: `${who} ја прифати вашата понуда за ${quoted}. Платете во готово на курирот при достава.`,
        }
        : {
          title: "Offer accepted",
          body: `${who} accepted your offer for ${quoted}. Pay the courier in cash on delivery.`,
        };
    case "offer_declined":
      return mk
        ? { title: "Понудата е одбиена", body: `Вашата понуда за ${quoted} е одбиена.` }
        : { title: "Offer declined", body: `Your offer for ${quoted} was declined.` };
    case "order_new":
      return mk
        ? { title: "Нова нарачка", body: `${who} нарача ${quoted} за ${price}.` }
        : { title: "New order", body: `${who} ordered ${quoted} for ${price}.` };
    case "order_paid":
      return mk
        ? { title: "Нарачката е прифатена", body: `${who} ја прифати вашата нарачка за ${quoted}.` }
        : { title: "Order accepted", body: `${who} accepted your order for ${quoted}.` };
    case "order_shipped":
      return mk
        ? {
          title: "Вашата нарачка е на пат",
          body: `${quoted} е испратена. Подгответе ${price} во готово за курирот.`,
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
    const parsed = JSON.parse(Deno.env.get("FCM_SERVICE_ACCOUNT") ?? "");
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

/** Compares secrets in constant time, so timing can't reveal them. */
function safeEqual(a: string, b: string): boolean {
  const x = new TextEncoder().encode(a);
  const y = new TextEncoder().encode(b);
  let diff = x.length ^ y.length;
  for (let i = 0; i < Math.max(x.length, y.length); i++) {
    diff |= (x[i] ?? 0) ^ (y[i] ?? 0);
  }
  return diff === 0;
}

function json(body: unknown): Response {
  return new Response(JSON.stringify(body), {
    headers: { "Content-Type": "application/json" },
  });
}
