import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// --- Stream server-side helpers ---

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
    console.error("STREAM_API_SECRET not configured — skipping Stream channel creation");
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
        data:        { created_by_id: proId },
        add_members: [{ user_id: proId }, { user_id: clientId }],
      }),
    }
  );
  if (!res.ok) {
    console.error(`Stream channel creation failed (${res.status}): ${await res.text()}`);
  }
}

// Valid state machine transitions — mirrors WorkOrderStatus state machine exactly
const VALID_TRANSITIONS: Record<string, string[]> = {
  "pending":            ["ready_to_navigate"],
  "ready_to_navigate":  ["en_route"],
  "en_route":           ["arrived"],
  "pre_work":           ["active_billing", "paused"],
  "active_billing":     ["paused", "post_work"],
  "paused":             ["active_billing", "pre_work"],
  "post_work":          ["client_review"],
  "client_review":      ["completed", "disputed"],  // client-only transitions
};

// Transitions that the client (not the pro) is allowed to initiate
const CLIENT_TRANSITIONS = new Set(["client_review>completed", "client_review>disputed"]);

// Timeline event written for each transition key (currentStatus>newStatus)
const TRANSITION_EVENT: Record<string, string | null> = {
  "pending>ready_to_navigate":    "confirmed",
  "en_route>arrived":              "arrived",
  "pre_work>active_billing":       "started",
  "active_billing>paused":         "paused",
  "active_billing>post_work":      null,
  "paused>active_billing":         "resumed",
  "paused>pre_work":               "resumed",
  "post_work>client_review":       "completed",
  "client_review>completed":       "client_approved",
  "client_review>disputed":        "client_disputed",
};

serve(async (req) => {
  try {
    const jwt = req.headers.get("Authorization")?.replace("Bearer ", "");
    if (!jwt) return err("Unauthorized", 401);

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // Verify caller identity
    const { data: { user }, error: authErr } = await supabase.auth.getUser(jwt);
    if (authErr || !user) return err("Unauthorized", 401);

    const { work_order_id, new_status, trigger } = await req.json();
    if (!work_order_id || !new_status) return err("Missing work_order_id or new_status", 400);

    // Fetch current work order
    const { data: order, error: fetchErr } = await supabase
      .from("work_orders")
      .select("*")
      .eq("id", work_order_id)
      .single();

    if (fetchErr || !order) return err("Work order not found", 404);

    const currentStatus: string = order.status;
    const transitionKey = `${currentStatus}>${new_status}`;
    const isClientTransition = CLIENT_TRANSITIONS.has(transitionKey);

    if (isClientTransition) {
      if (order.client_id !== user.id) return err("Forbidden", 403);
    } else {
      if (order.pro_id !== user.id) return err("Forbidden", 403);
    }

    const allowed = VALID_TRANSITIONS[currentStatus] ?? [];
    if (!allowed.includes(new_status)) {
      return err(`Invalid transition: ${currentStatus} → ${new_status}`, 422);
    }

    const now = new Date().toISOString();

    // arrived → auto-transitions to pre_work (two-step, atomic in sequence)
    if (new_status === "arrived") {
      await supabase.from("work_orders")
        .update({ status: "arrived", updated_at: now })
        .eq("id", work_order_id);

      await supabase.from("timeline_events").insert({
        work_order_id,
        event_type: "arrived",
        actor_id: user.id,
        actor_role: "pro",
        occurred_at: now,
      });

      const { data: final, error: finalErr } = await supabase
        .from("work_orders")
        .update({ status: "pre_work", updated_at: now })
        .eq("id", work_order_id)
        .select()
        .single();

      if (finalErr) return err(finalErr.message, 500);
      return ok(final);
    }

    // Build update payload
    const update: Record<string, unknown> = { status: new_status, updated_at: now };

    if (new_status === "active_billing" && currentStatus === "pre_work") {
      // Starting billing fresh
      update.billing_start_at = now;
      update.elapsed_billing_seconds = order.elapsed_billing_seconds ?? 0;
      update.paused_return_status = null;

    } else if (new_status === "active_billing" && currentStatus === "paused") {
      // Resuming — set a new wall-clock anchor; elapsed is already accumulated
      update.billing_start_at = now;
      update.paused_return_status = null;

    } else if (new_status === "paused") {
      // Accumulate elapsed before pausing
      let elapsed: number = order.elapsed_billing_seconds ?? 0;
      if (order.billing_start_at) {
        const startMs = new Date(order.billing_start_at).getTime();
        elapsed += (Date.now() - startMs) / 1000;
      }
      update.elapsed_billing_seconds = elapsed;
      update.billing_start_at = null;
      update.paused_return_status = currentStatus;

    } else if (new_status === "post_work") {
      // Stop billing — lock elapsed
      let elapsed: number = order.elapsed_billing_seconds ?? 0;
      if (order.billing_start_at) {
        const startMs = new Date(order.billing_start_at).getTime();
        elapsed += (Date.now() - startMs) / 1000;
      }
      update.elapsed_billing_seconds = elapsed;
      update.billing_start_at = null;

    } else if (new_status === "client_review") {
      // Lock final financials at completion
      const { data: materials } = await supabase
        .from("material_items")
        .select("amount")
        .eq("work_order_id", work_order_id);

      const elapsed: number = order.elapsed_billing_seconds ?? 0;
      const billableSeconds = Math.max(elapsed, 3600); // 1-hour minimum
      const laborTotal = (billableSeconds / 3600) * (order.hourly_rate ?? 0);
      const materialsTotal = (materials ?? []).reduce(
        (sum: number, m: { amount: number }) => sum + (m.amount ?? 0),
        0
      );

      update.labor_total = laborTotal;
      update.materials_total = materialsTotal;
      update.total_paid = laborTotal + materialsTotal;
      update.completed_at = now;
      update.payout_status = "pending";
      update.review_deadline = new Date(Date.now() + 2 * 60 * 60 * 1000).toISOString();

    } else if (new_status === "completed") {
      update.completed_at = now; // stamp actual completion for 72-hour chat window
    } else if (new_status === "pre_work") {
      update.paused_return_status = null;
    }

    const { data: updated, error: updateErr } = await supabase
      .from("work_orders")
      .update(update)
      .eq("id", work_order_id)
      .select()
      .single();

    if (updateErr) return err(updateErr.message, 500);

    // Write timeline event
    const key = `${currentStatus}>${new_status}`;
    const eventType = trigger === "auto_pause" ? "auto_paused" : TRANSITION_EVENT[key];
    if (eventType) {
      await supabase.from("timeline_events").insert({
        work_order_id,
        event_type: eventType,
        actor_id: user.id,
        actor_role: isClientTransition ? "client" : "pro",
        occurred_at: now,
      });
    }

    // Create the Stream chat channel when Pro accepts the job
    if (new_status === "ready_to_navigate") {
      await ensureStreamChannel(order.pro_id, order.client_id, work_order_id);
    }

    return ok(updated);
  } catch (e) {
    return err(String(e), 500);
  }
});

function ok(order: unknown) {
  return new Response(JSON.stringify({ success: true, order }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
}

function err(message: string, status: number) {
  return new Response(JSON.stringify({ success: false, error: message }), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
