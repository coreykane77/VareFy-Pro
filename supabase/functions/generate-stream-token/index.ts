import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const STREAM_SECRET = Deno.env.get("STREAM_SECRET")!;
const STREAM_API_KEY = "ceexz838897y";

function base64url(input: string | Uint8Array): string {
  let str: string;
  if (typeof input === "string") {
    str = btoa(unescape(encodeURIComponent(input)));
  } else {
    str = btoa(String.fromCharCode(...input));
  }
  return str.replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "");
}

async function signJwt(payload: Record<string, unknown>): Promise<string> {
  const header  = base64url(JSON.stringify({ alg: "HS256", typ: "JWT" }));
  const body    = base64url(JSON.stringify(payload));
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(STREAM_SECRET),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"]
  );
  const sig = await crypto.subtle.sign("HMAC", key, encoder.encode(`${header}.${body}`));
  return `${header}.${body}.${base64url(new Uint8Array(sig))}`;
}

async function upsertStreamUser(userId: string, name: string): Promise<void> {
  const serverToken = await signJwt({ server: true });
  const resp = await fetch(
    `https://chat.stream-io-api.com/users?api_key=${STREAM_API_KEY}`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": serverToken,
        "stream-auth-type": "jwt",
      },
      body: JSON.stringify({
        users: { [userId]: { id: userId, name } },
      }),
    }
  );
  if (!resp.ok) {
    console.error("Stream upsert failed:", await resp.text());
  }
}

serve(async (req) => {
  try {
    const jwt = req.headers.get("Authorization")?.replace("Bearer ", "");
    if (!jwt) return res({ error: "Unauthorized" }, 401);

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const { data: { user }, error } = await supabase.auth.getUser(jwt);
    if (error || !user) return res({ error: "Unauthorized" }, 401);

    const { data: profile } = await supabase
      .from("profiles")
      .select("display_name")
      .eq("id", user.id)
      .single();

    const displayName = profile?.display_name ?? user.id;

    await upsertStreamUser(user.id, displayName);

    const token = await signJwt({ user_id: user.id });
    return res({ token, user_id: user.id }, 200);
  } catch (e) {
    return res({ error: String(e) }, 500);
  }
});

function res(body: unknown, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
