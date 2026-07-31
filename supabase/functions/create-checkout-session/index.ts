import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { getStripe, isPlanKey, priceIdForPlan } from "../_shared/stripe.ts";
import { serviceClient, userClient } from "../_shared/supabase.ts";

type Platform = "desktop" | "mobile" | "web";

function redirectUrls(platform: Platform) {
  const desktopPort = Deno.env.get("SUBSCRIPTION_DESKTOP_PORT") ?? "54722";
  const desktopHost = Deno.env.get("SUBSCRIPTION_DESKTOP_HOST") ?? "127.0.0.1";
  const mobileScheme = Deno.env.get("SUBSCRIPTION_MOBILE_SCHEME") ?? "carebridge";
  const webBase = Deno.env.get("SUBSCRIPTION_WEB_URL") ?? "";

  switch (platform) {
    case "desktop":
      return {
        success: `http://${desktopHost}:${desktopPort}/?session_id={CHECKOUT_SESSION_ID}`,
        cancel: `http://${desktopHost}:${desktopPort}/?cancelled=true`,
      };
    case "mobile":
      return {
        success: `${mobileScheme}://subscription-success?session_id={CHECKOUT_SESSION_ID}`,
        cancel: `${mobileScheme}://subscription-cancel`,
      };
    case "web":
      if (!webBase) {
        throw new Error("SUBSCRIPTION_WEB_URL is required for web checkout");
      }
      return {
        success: `${webBase}/subscription-success?session_id={CHECKOUT_SESSION_ID}`,
        cancel: `${webBase}/subscription-cancel`,
      };
  }
}

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
    const planKey = body?.plan_key;
    const platform = (body?.platform ?? "desktop") as Platform;

    if (!isPlanKey(planKey)) {
      return jsonResponse({ error: "Invalid plan_key" }, 400);
    }

    const stripe = getStripe();
    const admin = serviceClient();
    const priceId = priceIdForPlan(planKey);
    const urls = redirectUrls(platform);

    let stripeCustomerId: string | null = null;
    const { data: existing } = await admin
      .from("stripe_customers")
      .select("stripe_customer_id")
      .eq("user_id", user.id)
      .maybeSingle();

    if (existing?.stripe_customer_id) {
      stripeCustomerId = existing.stripe_customer_id;
    } else {
      const customer = await stripe.customers.create({
        email: user.email ?? undefined,
        metadata: { supabase_user_id: user.id },
      });
      stripeCustomerId = customer.id;
      await admin.from("stripe_customers").upsert({
        user_id: user.id,
        stripe_customer_id: customer.id,
        email: user.email,
      });
    }

    const [planRole, billingCycle] = planKey.split("_") as [
      "family" | "volunteer",
      "monthly" | "yearly",
    ];

    const session = await stripe.checkout.sessions.create({
      mode: "subscription",
      customer: stripeCustomerId,
      line_items: [{ price: priceId, quantity: 1 }],
      success_url: urls.success,
      cancel_url: urls.cancel,
      allow_promotion_codes: true,
      billing_address_collection: "auto",
      client_reference_id: user.id,
      metadata: {
        supabase_user_id: user.id,
        plan_key: planKey,
        plan_role: planRole,
        billing_cycle: billingCycle,
      },
      subscription_data: {
        metadata: {
          supabase_user_id: user.id,
          plan_key: planKey,
          plan_role: planRole,
          billing_cycle: billingCycle,
        },
      },
    });

    return jsonResponse({
      url: session.url,
      session_id: session.id,
    });
  } catch (e) {
    console.error("create-checkout-session", e);
    const message = e instanceof Error ? e.message : "Checkout failed";
    return jsonResponse({ error: message }, 500);
  }
});
