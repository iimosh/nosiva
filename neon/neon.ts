// Nosiva's backend on Neon: sign-in, the database's HTTP API, photo storage
// and server functions. Apply with `neon deploy` from this folder.
//
// Secrets never live in this file. Function env values are read from the
// shell or a local, git-ignored .env file when `neon deploy` runs.
import { defineConfig } from "@neon/config/v1";

export default defineConfig({
  // Email + password and Google sign-in (Managed Better Auth).
  auth: true,

  // PostgREST-compatible API the app talks to; every request runs as the
  // signed-in user, so the row-level security rules decide what they see.
  dataApi: true,

  buckets: {
    // Listing photos and avatars are public, like on any marketplace.
    "listing-images": { access: "public_read" },
    avatars: { access: "public_read" },
    // Chat photos are private: only the two people in the chat get a
    // short-lived link to them (see functions/media.ts).
    "chat-images": { access: "private" },
  },

  functions: {
    // Upload links, private chat-photo links, account photo cleanup.
    media: { name: "Media", source: "./functions/media.ts" },
    // Google sign-in's last hop: forwards the browser back into the app
    // (its address is a trusted domain in Neon Auth).
    authbounce: { name: "Sign-in return", source: "./functions/authbounce.ts" },
    // Sends push notifications waiting in private.push_outbox.
    push: {
      name: "Push notifications",
      source: "./functions/push.ts",
      // The Firebase key comes from the git-ignored .env.secrets
      // (`npm run save-fcm-key -- <key file>`, then `npm run deploy`).
      // Without it the function still deploys; it just can't send yet.
      env: {
        ...(process.env.FCM_SERVICE_ACCOUNT
          ? { FCM_SERVICE_ACCOUNT: process.env.FCM_SERVICE_ACCOUNT }
          : {}),
      },
    },
  },

  triggers: {
    // Safety net: sends anything the app's instant nudge missed (e.g. the
    // phone lost signal right after sending). Hourly, not more often: each
    // run wakes the database, and a database woken every few minutes never
    // sleeps — which would use up the free plan's compute hours.
    pushHourly: {
      type: "schedule",
      function: "push",
      cron: "0 * * * *",
      functionPath: "/flush",
    },
    // Deletes photo files nothing uses any more (removed listing photos,
    // replaced avatars, deleted chats). Nightly at 03:17 UTC.
    photoCleanup: {
      type: "schedule",
      function: "media",
      cron: "17 3 * * *",
      functionPath: "/cleanup",
    },
  },

  branch: (branch) => {
    // (Branch protection isn't available on the free plan.)
    if (branch.isDefault) return {};
    // Test branches clean themselves up.
    if (!branch.exists) return { ttl: "7d" };
    return {};
  },
});
