import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { getStripe, isPlanKey, type PlanKey } from "../_shared/stripe.ts";
import { upsertSubscriptionFromStripe } from "../_shared/sync.ts";
import { serviceClient, userClient } from "../_shared/supabase.ts";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse({ error: "Missing authorization" }, 401);
    }

    const supabaseUser = userClient(authHeader);
    const { data: { user }, error: userError } = await supabaseUser.auth.getUser();
    if (userError || !user) {
      return jsonResponse({ error: "Unauthorized" }, 401);
    }

    const body = await req.json();
    const sessionId = body?.session_id as string | undefined;
    if (!sessionId) {
      return jsonResponse({ error: "session_id required" }, 400);
    }

    const stripe = getStripe();
    const admin = serviceClient();

    const session = await stripe.checkout.sessions.retrieve(sessionId, {
      expand: ["subscription"],
    });

    if (session.client_reference_id !== user.id &&
      session.metadata?.supabase_user_id !== user.id) {
      return jsonResponse({ error: "Session does not belong to this user" }, 403);
    }

    if (session.payment_status !== "paid" && session.status !== "complete") {
      return jsonResponse({
        active: false,
        status: session.status,
        payment_status: session.payment_status,
      });
    }

    const planKey = session.metadata?.plan_key;
    const fallback = isPlanKey(planKey ?? "") ? (planKey as PlanKey) : undefined;

    let subscription;
    if (typeof session.subscription === "string") {
      subscription = await stripe.subscriptions.retrieve(session.subscription);
    } else if (session.subscription) {
      subscription = session.subscription;
    } else {
      return jsonResponse({ active: false, error: "No subscription on session" });
    }

    await upsertSubscriptionFromStripe(admin, subscription, fallback);

    const { data: row } = await admin
      .from("subscriptions")
      .select("status, plan_role, billing_cycle, current_period_end")
      .eq("user_id", user.id)
      .in("status", ["active", "trialing"])
      .order("current_period_end", { ascending: false })
      .limit(1)
      .maybeSingle();

    return jsonResponse({
      active: row?.status === "active" || row?.status === "trialing",
      subscription: row,
    });
  } catch (e) {
    console.error("verify-checkout-session", e);
    const message = e instanceof Error ? e.message : "Verification failed";
    return jsonResponse({ error: message }, 500);
  }
});
