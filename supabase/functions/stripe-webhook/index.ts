import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { getStripe, isPlanKey, type PlanKey } from "../_shared/stripe.ts";
import { recordInvoicePayment, upsertSubscriptionFromStripe } from "../_shared/sync.ts";
import { serviceClient } from "../_shared/supabase.ts";

serve(async (req) => {
  const signature = req.headers.get("stripe-signature");
  if (!signature) {
    return new Response("Missing stripe-signature", { status: 400 });
  }

  const webhookSecret = Deno.env.get("STRIPE_WEBHOOK_SECRET");
  if (!webhookSecret) {
    return new Response("STRIPE_WEBHOOK_SECRET not configured", { status: 500 });
  }

  const stripe = getStripe();
  const admin = serviceClient();
  const body = await req.text();

  let event;
  try {
    event = await stripe.webhooks.constructEventAsync(body, signature, webhookSecret);
  } catch (err) {
    console.error("Webhook signature verification failed", err);
    return new Response("Invalid signature", { status: 400 });
  }

  try {
    switch (event.type) {
      case "checkout.session.completed": {
        const session = event.data.object;
        const userId = session.metadata?.supabase_user_id ??
          session.client_reference_id;
        if (!userId) break;

        if (session.subscription) {
          const subId = typeof session.subscription === "string"
            ? session.subscription
            : session.subscription.id;
          const sub = await stripe.subscriptions.retrieve(subId);
          const planKey = session.metadata?.plan_key;
          await upsertSubscriptionFromStripe(
            admin,
            sub,
            isPlanKey(planKey ?? "") ? (planKey as PlanKey) : undefined,
          );
        }
        break;
      }

      case "customer.subscription.created":
      case "customer.subscription.updated": {
        const sub = event.data.object;
        const planKey = sub.metadata?.plan_key;
        await upsertSubscriptionFromStripe(
          admin,
          sub,
          isPlanKey(planKey ?? "") ? (planKey as PlanKey) : undefined,
        );
        break;
      }

      case "customer.subscription.deleted": {
        const sub = event.data.object;
        const userId = sub.metadata?.supabase_user_id;
        if (!userId) break;

        await admin.from("subscriptions").update({
          status: "canceled",
          canceled_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        }).eq("stripe_subscription_id", sub.id);

        await admin.rpc("sync_profile_subscription", { p_user_id: userId });
        break;
      }

      case "invoice.paid": {
        await recordInvoicePayment(admin, event.data.object);
        break;
      }

      case "invoice.payment_failed": {
        const invoice = event.data.object;
        const userId = invoice.metadata?.supabase_user_id;
        if (userId && invoice.subscription) {
          const subId = typeof invoice.subscription === "string"
            ? invoice.subscription
            : invoice.subscription.id;
          const sub = await stripe.subscriptions.retrieve(subId);
          await upsertSubscriptionFromStripe(admin, sub);
        }
        break;
      }

      default:
        console.log(`Unhandled event type: ${event.type}`);
    }
  } catch (e) {
    console.error("Webhook handler error", event.type, e);
    return new Response("Webhook handler failed", { status: 500 });
  }

  return new Response(JSON.stringify({ received: true }), {
    headers: { "Content-Type": "application/json" },
  });
});
