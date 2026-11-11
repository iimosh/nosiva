// The last hop of Google sign-in.
//
// Neon Auth only sends the browser back to web (https) addresses, never
// straight into an app. So after Google, Neon sends it here, and this
// forwards it at once to mk.nosiva.app://neon-callback — which closes the
// sign-in tab and hands the result to the app (NeonAuth.signInWithGoogle).
//
// What passes through (a one-time "verifier", or an error) is useless on
// its own: the app exchanges it together with a secret challenge cookie
// that never leaves the phone. The target is fixed, so this can't be used
// to send anyone anywhere else.
//
// This function's address must be a trusted domain in Neon Auth:
//   neon neon-auth domain add <this function's URL>
const APP_CALLBACK = "mk.nosiva.app://neon-callback";
const VERIFIER = "neon_auth_session_verifier";

export default {
  async fetch(request: Request): Promise<Response> {
    if (request.method !== "GET") {
      return new Response("Use GET", { status: 405 });
    }
    const query = new URL(request.url).searchParams;
    if (!query.has(VERIFIER) && !query.has("error")) {
      return new Response("Not found", { status: 404 });
    }
    return new Response(null, {
      status: 302,
      headers: {
        location: `${APP_CALLBACK}?${query.toString()}`,
        "cache-control": "no-store",
        "referrer-policy": "no-referrer",
      },
    });
  },
};
