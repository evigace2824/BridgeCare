import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { getStripe } from "../_shared/stripe.ts";
import { serviceClient, userClient } from "../_shared/supabase.ts";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) return jsonResponse({ error: "Missing authorization" }, 401);

    const supabaseUser = userClient(authHeader);
    const { data: { user }, error: userError } = await supabaseUser.auth.getUser();
    if (userError || !user) return jsonResponse({ error: "Unauthorized" }, 401);

    const body = await req.json().catch(() => ({}));
    const returnUrl = body?.return_url as string | undefined;
    if (!returnUrl) {
      return jsonResponse({ error: "return_url required" }, 400);
    }

    const admin = serviceClient();
    const { data: customer } = await admin
      .from("stripe_customers")
      .select("stripe_customer_id")
      .eq("user_id", user.id)
      .maybeSingle();

    if (!customer?.stripe_customer_id) {
      return jsonResponse({ error: "No billing account found" }, 404);
    }

    const stripe = getStripe();
    const portal = await stripe.billingPortal.sessions.create({
      customer: customer.stripe_customer_id,
      return_url: returnUrl,
    });

    return jsonResponse({ url: portal.url });
  } catch (e) {
    console.error("create-portal-session", e);
    const message = e instanceof Error ? e.message : "Portal session failed";
    return jsonResponse({ error: message }, 500);
  }
});
