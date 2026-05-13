import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

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

    const {
      work_order_id,
      estimated_hours,
      estimated_materials = 0,
      proposed_start_date,
      title = null,
      description = null,
      valid_for_days = 30,
    } = await req.json();

    if (!work_order_id || !estimated_hours || !proposed_start_date) {
      return err("Missing required fields: work_order_id, estimated_hours, proposed_start_date", 400);
    }

    const { data: order, error: fetchErr } = await supabase
      .from("work_orders")
      .select("id, pro_id, status, hourly_rate")
      .eq("id", work_order_id)
      .single();

    if (fetchErr || !order) return err("Work order not found", 404);
    if (order.pro_id !== user.id) return err("Forbidden", 403);

    const validStatuses = ["active_billing", "paused"];
    if (!validStatuses.includes(order.status)) {
      return err(`Estimates can only be created during an active job (current: ${order.status})`, 422);
    }

    const estimatedTotal =
      (Number(estimated_hours) * Number(order.hourly_rate)) + Number(estimated_materials);

    const now = new Date().toISOString();

    const { data: estimate, error: insertErr } = await supabase
      .from("estimates")
      .insert({
        work_order_id,
        title,
        description,
        valid_for_days: Number(valid_for_days) || 30,
        estimated_hours: Number(estimated_hours),
        estimated_materials: Number(estimated_materials),
        estimated_total: estimatedTotal,
        proposed_start_date,
        materials_deposit_enabled: false,
        materials_deposit_amount: 0,
        status: "pending",
        created_at: now,
      })
      .select()
      .single();

    if (insertErr) return err(insertErr.message, 500);

    await supabase.from("timeline_events").insert({
      work_order_id,
      event_type: "estimate_sent",
      actor_id: user.id,
      actor_role: "pro",
      metadata: {
        estimate_id: estimate.id,
        estimated_hours: Number(estimated_hours),
        estimated_total: estimatedTotal,
      },
      occurred_at: now,
    });

    return ok(estimate);
  } catch (e) {
    return err(String(e), 500);
  }
});

function ok(data: unknown) {
  return new Response(JSON.stringify({ success: true, estimate: data }), {
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
