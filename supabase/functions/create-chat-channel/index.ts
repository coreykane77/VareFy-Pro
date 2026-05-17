import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

function base64url(input: string | ArrayBuffer): string {
  const bytes = typeof input === "string"
    ? new TextEncoder().encode(input)
    : new Uint8Array(input as ArrayBuffer);
  const str = btoa(String.fromCharCode(...bytes));
  return str.replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function streamServerJwt(secret: string): Promise<string> {
  const header  = base64url(JSON.stringify({ alg: "HS256", typ: "JWT" }));
  const payload = base64url(JSON.stringify({ server: true }));
  const input   = `${header}.${payload}`;
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"]
  );
  const sig = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(input));
  return `${input}.${base64url(sig)}`;
}

async function ensureStreamChannel(proId: string, clientId: string, workOrderId: string): Promise<void> {
  const apiKey    = Deno.env.get("STREAM_API_KEY") ?? "ceexz838897y";
  const apiSecret = Deno.env.get("STREAM_API_SECRET");
  if (!apiSecret) {
    console.error("STREAM_API_SECRET not configured");
    return;
  }
  const channelId = `work_order_${workOrderId.toLowerCase()}`;
  const token     = await streamServerJwt(apiSecret);
  const res = await fetch(
    `https://chat.stream-io-api.com/channels/messaging/${channelId}?api_key=${apiKey}`,
    {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${token}`,
        "stream-auth-type": "jwt",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        data:    { created_by_id: proId },
        members: [{ user_id: proId }, { user_id: clientId }],
      }),
    }
  );
  if (!res.ok) {
    console.error(`Stream channel creation failed (${res.status}): ${await res.text()}`);
  }
}

serve(async (req) => {
  try {
    const jwt = req.headers.get("Authorization")?.replace("Bearer ", "");
    if (!jwt) return err("Unauthorized", 401);

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const { data: { user }, error: authErr } = await supabase.auth.getUser(jwt);
    if (authErr || !user) return err("Unauthorized", 401);

    const { work_order_id, pro_id, client_id } = await req.json();
    if (!work_order_id || !pro_id || !client_id) {
      return err("Missing work_order_id, pro_id, or client_id", 400);
    }

    await ensureStreamChannel(pro_id, client_id, work_order_id);

    return new Response(JSON.stringify({ success: true }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    return err(String(e), 500);
  }
});

function err(message: string, status: number) {
  return new Response(JSON.stringify({ success: false, error: message }), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
