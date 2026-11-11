// Shared by Nosiva's Neon Functions: JSON responses, checking who is signed
// in, and the database connection.
import { createRemoteJWKSet, jwtVerify } from "jose";
import pg from "pg";

export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });
}

export const UUID =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const jwks = createRemoteJWKSet(new URL(process.env.NEON_AUTH_JWKS_URL!));

/**
 * The signed-in user's id from the request's `Authorization: Bearer <JWT>`
 * (a Neon Auth token, checked against Neon Auth's public keys), or null.
 */
export async function signedInUser(request: Request): Promise<string | null> {
  const header = request.headers.get("authorization") ?? "";
  if (!header.startsWith("Bearer ")) return null;
  try {
    const { payload } = await jwtVerify(header.slice("Bearer ".length), jwks);
    return typeof payload.sub === "string" && UUID.test(payload.sub)
      ? payload.sub
      : null;
  } catch {
    return null;
  }
}

/**
 * True for calls made by a Neon schedule trigger. Neon strips any
 * client-set `X-Neon-*` header, so outsiders can't fake this one.
 */
export function fromNeonSchedule(request: Request): boolean {
  return request.headers.has("x-neon-trigger-invocation-id");
}

let pool: pg.Pool | null = null;

/** Database connection as the owner role — bypasses row-level security, so
 * every query here must check permissions itself. */
export function db(): pg.Pool {
  pool ??= new pg.Pool({
    // verify-full: the strictest TLS check (and silences pg's sslmode warning).
    connectionString: process.env.DATABASE_URL!.replace(
      /sslmode=(require|prefer|verify-ca)/,
      "sslmode=verify-full",
    ),
    max: 3,
  });
  return pool;
}
