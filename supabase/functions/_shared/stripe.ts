import Stripe from "https://esm.sh/stripe@14.21.0?target=deno";

export function getStripe(): Stripe {
  const key = Deno.env.get("STRIPE_SECRET_KEY");
  if (!key) throw new Error("STRIPE_SECRET_KEY is not configured");
  return new Stripe(key, { apiVersion: "2023-10-16", httpClient: Stripe.createFetchClient() });
}

export type PlanKey =
  | "family_monthly"
  | "family_yearly"
  | "volunteer_monthly"
  | "volunteer_yearly";

export function priceIdForPlan(planKey: PlanKey): string {
  const map: Record<PlanKey, string | undefined> = {
    family_monthly: Deno.env.get("STRIPE_PRICE_FAMILY_MONTHLY"),
    family_yearly: Deno.env.get("STRIPE_PRICE_FAMILY_YEARLY"),
    volunteer_monthly: Deno.env.get("STRIPE_PRICE_VOLUNTEER_MONTHLY"),
    volunteer_yearly: Deno.env.get("STRIPE_PRICE_VOLUNTEER_YEARLY"),
  };
  const id = map[planKey];
  if (!id) throw new Error(`Stripe price not configured for plan: ${planKey}`);
  return id;
}

export function parsePlanKey(planKey: string): {
  planRole: "family" | "volunteer";
  billingCycle: "monthly" | "yearly";
} {
  const [role, cycle] = planKey.split("_");
  if (
    (role !== "family" && role !== "volunteer") ||
    (cycle !== "monthly" && cycle !== "yearly")
  ) {
    throw new Error(`Invalid plan_key: ${planKey}`);
  }
  return { planRole: role, billingCycle: cycle };
}

export function isPlanKey(value: string): value is PlanKey {
  return (
    value === "family_monthly" ||
    value === "family_yearly" ||
    value === "volunteer_monthly" ||
    value === "volunteer_yearly"
  );
}
