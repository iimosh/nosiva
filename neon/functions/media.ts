// Photos for Nosiva: hands out short-lived upload links, private chat-photo
// links, and empties a user's folders when they delete their account.
//
// Replaces Supabase Storage's rules with the same limits:
//   * only signed-in people can upload, and only into their own folder
//     (the folder comes from the verified sign-in token, never the request);
//   * chat photos only into a conversation they're part of;
//   * images only: 8 MB listing photos, 5 MB avatars, 10 MB chat photos.
// The storage keys stay here on the server; phones only get one-off links.
//
// Routes (all POST, all need `Authorization: Bearer <Neon Auth JWT>`):
//   /upload       {kind, contentType, size, listingId?, conversationId?}
//                 -> {uploadUrl, path, publicUrl?}
//   /chat-photo   {path} -> {url}   (1-hour link, chat participants only)
//   /delete-mine  -> {deleted}      (call before deleting the account)
//
// And one route only Neon's nightly schedule can call (neon.ts):
//   /cleanup      deletes photo files nothing uses any more (see below)
import {
  DeleteObjectCommand,
  GetObjectCommand,
  ListObjectsV2Command,
  PutObjectCommand,
  S3Client,
} from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";

import { db, fromNeonSchedule, json, signedInUser, UUID } from "./lib/common";

const endpoint = process.env.AWS_ENDPOINT_URL_S3!;
const s3 = new S3Client({
  region: process.env.AWS_REGION,
  endpoint,
  forcePathStyle: true,
  requestChecksumCalculation: "WHEN_REQUIRED",
});

const MB = 1024 * 1024;
const IMAGE_TYPES: Record<string, string> = {
  "image/jpeg": "jpg",
  "image/png": "png",
  "image/webp": "webp",
  "image/heic": "heic",
  "image/heif": "heif",
};

const KINDS = {
  listing: { bucket: "listing-images", maxBytes: 8 * MB, types: IMAGE_TYPES, isPublic: true },
  avatar: { bucket: "avatars", maxBytes: 5 * MB, types: IMAGE_TYPES, isPublic: true },
  chat: {
    bucket: "chat-images",
    maxBytes: 10 * MB,
    types: { ...IMAGE_TYPES, "image/gif": "gif" } as Record<string, string>,
    isPublic: false,
  },
} as const;

type Kind = keyof typeof KINDS;

const CHAT_PATH = /^([0-9a-f-]{36})\/([0-9a-f-]{36})\/[A-Za-z0-9._-]+$/i;

async function isParticipant(conversationId: string, userId: string): Promise<boolean> {
  const { rowCount } = await db().query(
    `select 1 from public.conversations
      where id = $1 and (buyer_id = $2 or seller_id = $2)`,
    [conversationId, userId],
  );
  return (rowCount ?? 0) > 0;
}

async function upload(userId: string, body: Record<string, unknown>): Promise<Response> {
  const kind = body.kind as Kind;
  const rule = KINDS[kind];
  if (!rule) return json({ error: "Unknown photo kind" }, 400);

  const contentType = body.contentType;
  const ext = typeof contentType === "string" ? rule.types[contentType] : undefined;
  if (!ext) return json({ error: "Only images can be uploaded" }, 415);

  const size = body.size;
  if (typeof size !== "number" || !Number.isInteger(size) || size <= 0 || size > rule.maxBytes) {
    return json({ error: "Image too large" }, 413);
  }

  const file = `${crypto.randomUUID()}.${ext}`;
  let path: string;
  if (kind === "listing") {
    const listingId = body.listingId;
    if (typeof listingId !== "string" || !UUID.test(listingId)) {
      return json({ error: "Invalid listing" }, 400);
    }
    path = `${userId}/${listingId}/${file}`;
  } else if (kind === "avatar") {
    path = `${userId}/${file}`;
  } else {
    const conversationId = body.conversationId;
    if (typeof conversationId !== "string" || !UUID.test(conversationId)) {
      return json({ error: "Invalid conversation" }, 400);
    }
    if (!(await isParticipant(conversationId, userId))) {
      return json({ error: "Not allowed" }, 403);
    }
    path = `${conversationId}/${userId}/${file}`;
  }

  // Signing the type and size makes storage reject any other file.
  const uploadUrl = await getSignedUrl(
    s3,
    new PutObjectCommand({
      Bucket: rule.bucket,
      Key: path,
      ContentType: contentType as string,
      ContentLength: size,
    }),
    { expiresIn: 300, signableHeaders: new Set(["content-type", "content-length"]) },
  );

  return json({
    uploadUrl,
    path,
    ...(rule.isPublic ? { publicUrl: `${endpoint}/${rule.bucket}/${path}` } : {}),
  });
}

async function chatPhoto(userId: string, body: Record<string, unknown>): Promise<Response> {
  const path = body.path;
  const match = typeof path === "string" && !path.includes("..") ? CHAT_PATH.exec(path) : null;
  if (!match) return json({ error: "Invalid photo" }, 400);
  if (!(await isParticipant(match[1], userId))) return json({ error: "Not allowed" }, 403);

  const url = await getSignedUrl(
    s3,
    new GetObjectCommand({ Bucket: KINDS.chat.bucket, Key: path as string }),
    { expiresIn: 3600 },
  );
  return json({ url });
}

async function deleteFolder(bucket: string, prefix: string): Promise<number> {
  // One by one: batch deletes need a checksum header that S3-compatible
  // stores don't all accept.
  let deleted = 0;
  let token: string | undefined;
  do {
    const page = await s3.send(
      new ListObjectsV2Command({ Bucket: bucket, Prefix: prefix, ContinuationToken: token }),
    );
    const keys = (page.Contents ?? []).map((o) => o.Key!).filter(Boolean);
    for (let i = 0; i < keys.length; i += 10) {
      await Promise.all(
        keys.slice(i, i + 10).map((Key) => s3.send(new DeleteObjectCommand({ Bucket: bucket, Key }))),
      );
    }
    deleted += keys.length;
    token = page.IsTruncated ? page.NextContinuationToken : undefined;
  } while (token);
  return deleted;
}

async function deleteMine(userId: string): Promise<Response> {
  let deleted = 0;
  deleted += await deleteFolder(KINDS.listing.bucket, `${userId}/`);
  deleted += await deleteFolder(KINDS.avatar.bucket, `${userId}/`);
  const { rows } = await db().query(
    `select id from public.conversations where buyer_id = $1 or seller_id = $1`,
    [userId],
  );
  for (const { id } of rows) {
    deleted += await deleteFolder(KINDS.chat.bucket, `${id}/${userId}/`);
  }
  return json({ deleted });
}

// ---------------------------------------------------------------------------
// Nightly cleanup of unused photo files
// ---------------------------------------------------------------------------

/** Files younger than this are never deleted (they may be mid-upload). */
const CLEANUP_MIN_AGE_MS = 24 * 60 * 60 * 1000;
/** At most this many deletions per night, as a safety cap. */
const CLEANUP_MAX_DELETES = 500;
/**
 * While true, the cleanup only reports what it would delete. (A report was
 * checked by hand on 2026-11-10 — it flagged only a replaced avatar — so
 * it now deletes.)
 */
const CLEANUP_DRY_RUN = false;

/** Every key in a bucket, with when it was stored. */
async function listAll(bucket: string): Promise<{ key: string; modified: Date }[]> {
  const out: { key: string; modified: Date }[] = [];
  let token: string | undefined;
  do {
    const page = await s3.send(
      new ListObjectsV2Command({ Bucket: bucket, ContinuationToken: token }),
    );
    for (const o of page.Contents ?? []) {
      if (o.Key) out.push({ key: o.Key, modified: o.LastModified ?? new Date() });
    }
    token = page.IsTruncated ? page.NextContinuationToken : undefined;
  } while (token);
  return out;
}

/** The storage key inside a public photo address ("…/listing-images/<key>"). */
function keyFromUrl(url: string | null, bucket: string): string | null {
  if (!url) return null;
  const marker = `/${bucket}/`;
  const i = url.lastIndexOf(marker);
  return i < 0 ? null : decodeURIComponent(url.slice(i + marker.length));
}

/**
 * Deletes photo files that no listing, profile or message uses any more
 * (removed listing photos, replaced avatars, photos in deleted chats).
 * Safety: only files older than a day; stops for a bucket if the database
 * says nothing is in use while files exist (a failed or empty read must
 * never wipe storage); at most CLEANUP_MAX_DELETES per run.
 */
async function cleanup(): Promise<Record<string, unknown>> {
  const pool = db();
  const used = {
    [KINDS.listing.bucket]: new Set(
      (await pool.query(`select image_url from public.listing_images`)).rows
        .map((r) => keyFromUrl(r.image_url, KINDS.listing.bucket))
        .filter((k): k is string => !!k),
    ),
    [KINDS.avatar.bucket]: new Set(
      (await pool.query(`select avatar_url from public.profiles where avatar_url is not null`)).rows
        .map((r) => keyFromUrl(r.avatar_url, KINDS.avatar.bucket))
        .filter((k): k is string => !!k),
    ),
    // Chat messages store the storage path itself.
    [KINDS.chat.bucket]: new Set(
      (await pool.query(`select image_url from public.messages where image_url is not null`)).rows
        .map((r) => keyFromUrl(r.image_url, KINDS.chat.bucket) ?? r.image_url)
        .filter((k): k is string => !!k),
    ),
  };

  const report: Record<string, unknown> = { dryRun: CLEANUP_DRY_RUN };
  let budget = CLEANUP_MAX_DELETES;
  const cutoff = Date.now() - CLEANUP_MIN_AGE_MS;
  for (const [bucket, inUse] of Object.entries(used)) {
    const files = await listAll(bucket);
    if (files.length > 0 && inUse.size === 0) {
      report[bucket] = { skipped: "database says nothing is in use", files: files.length };
      continue;
    }
    const unused = files.filter((f) => !inUse.has(f.key) && f.modified.getTime() < cutoff);
    const toDelete = unused.slice(0, budget);
    if (!CLEANUP_DRY_RUN) {
      for (const f of toDelete) {
        await s3.send(new DeleteObjectCommand({ Bucket: bucket, Key: f.key }));
      }
      budget -= toDelete.length;
    }
    report[bucket] = {
      files: files.length,
      inUse: inUse.size,
      unused: unused.length,
      [CLEANUP_DRY_RUN ? "wouldDelete" : "deleted"]: toDelete.length,
      examples: toDelete.slice(0, 3).map((f) => f.key),
    };
  }
  console.log("photo cleanup", JSON.stringify(report));
  return report;
}

export default {
  async fetch(request: Request): Promise<Response> {
    if (request.method !== "POST") return json({ error: "Use POST" }, 405);
    if (new URL(request.url).pathname === "/cleanup") {
      if (!fromNeonSchedule(request)) return json({ error: "Not allowed" }, 403);
      try {
        return json(await cleanup());
      } catch (e) {
        console.error("photo cleanup failed", e);
        return json({ error: "Something went wrong" }, 500);
      }
    }
    const userId = await signedInUser(request);
    if (!userId) return json({ error: "Sign in required" }, 401);

    const body = ((await request.json().catch(() => null)) ?? {}) as Record<string, unknown>;
    try {
      switch (new URL(request.url).pathname) {
        case "/upload":
          return await upload(userId, body);
        case "/chat-photo":
          return await chatPhoto(userId, body);
        case "/delete-mine":
          return await deleteMine(userId);
        default:
          return json({ error: "Not found" }, 404);
      }
    } catch (e) {
      console.error("media failed", e);
      return json({ error: "Something went wrong" }, 500);
    }
  },
};
