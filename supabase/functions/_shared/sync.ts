import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import type Stripe from "https://esm.sh/stripe@14.21.0?target=deno";
import { parsePlanKey, type PlanKey } from "./stripe.ts";

export async function upsertSubscriptionFromStripe(
  admin: SupabaseClient,
  sub: Stripe.Subscription,
  fallbackPlanKey?: PlanKey,
): Promise<void> {
  const userId = sub.metadata?.supabase_user_id;
  if (!userId) {
    console.warn("Subscription missing supabase_user_id metadata", sub.id);
    return;
  }

  let planRole = sub.metadata?.plan_role as "family" | "volunteer" | undefined;
  let billingCycle = sub.metadata?.billing_cycle as "monthly" | "yearly" | undefined;
  const planKey = sub.metadata?.plan_key as PlanKey | undefined;

  if ((!planRole || !billingCycle) && (planKey || fallbackPlanKey)) {
    const parsed = parsePlanKey(planKey ?? fallbackPlanKey!);
    planRole = parsed.planRole;
    billingCycle = parsed.billingCycle;
  }

  if (!planRole || !billingCycle) {
    console.warn("Could not resolve plan metadata for subscription", sub.id);
    return;
  }

  const priceId = sub.items?.data?.[0]?.price?.id ?? null;
  const periodStart = sub.current_period_start
    ? new Date(sub.current_period_start * 1000).toISOString()
    : null;
  const periodEnd = sub.current_period_end
    ? new Date(sub.current_period_end * 1000).toISOString()
    : null;

  await admin.from("subscriptions").upsert(
    {
      user_id: userId,
      stripe_subscription_id: sub.id,
      stripe_customer_id: String(sub.customer),
      status: sub.status,
      plan_role: planRole,
      billing_cycle: billingCycle,
      stripe_price_id: priceId,
      current_period_start: periodStart,
      current_period_end: periodEnd,
      cancel_at_period_end: sub.cancel_at_period_end ?? false,
      canceled_at: sub.canceled_at
        ? new Date(sub.canceled_at * 1000).toISOString()
        : null,
      updated_at: new Date().toISOString(),
    },
    { onConflict: "stripe_subscription_id" },
  );

  await admin.rpc("sync_profile_subscription", { p_user_id: userId });
}

export async function recordInvoicePayment(
  admin: SupabaseClient,
  invoice: Stripe.Invoice,
): Promise<void> {
  const userId = invoice.subscription_details?.metadata?.supabase_user_id ??
    invoice.metadata?.supabase_user_id;
  if (!userId || !invoice.id) return;

  await admin.from("subscription_payments").upsert(
    {
      user_id: userId,
      stripe_invoice_id: invoice.id,
      stripe_payment_intent_id: typeof invoice.payment_intent === "string"
        ? invoice.payment_intent
        : invoice.payment_intent?.id ?? null,
      amount_cents: invoice.amount_paid ?? 0,
      currency: invoice.currency ?? "usd",
      status: invoice.status ?? "paid",
    },
    { onConflict: "stripe_invoice_id" },
  );
}
