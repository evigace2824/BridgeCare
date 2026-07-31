# Stripe subscriptions for BridgeCare

Real premium billing uses **Stripe Checkout** + **Supabase Edge Functions**. Card data never touches your app or database.

## 1. Stripe Dashboard

1. Create a [Stripe account](https://dashboard.stripe.com/register).
2. **Products** → create two products:
   - **Family Premium** — prices: $19.99/month, $149/year
   - **Volunteer Premium** — prices: $9.99/month, $99/year
3. Copy each **Price ID** (`price_...`).

## 2. Supabase secrets

In **Project Settings → Edge Functions → Secrets**, add:

| Secret | Example |
|--------|---------|
| `STRIPE_SECRET_KEY` | `sk_test_...` |
| `STRIPE_WEBHOOK_SECRET` | `whsec_...` |
| `STRIPE_PRICE_FAMILY_MONTHLY` | `price_...` |
| `STRIPE_PRICE_FAMILY_YEARLY` | `price_...` |
| `STRIPE_PRICE_VOLUNTEER_MONTHLY` | `price_...` |
| `STRIPE_PRICE_VOLUNTEER_YEARLY` | `price_...` |

`SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_SERVICE_ROLE_KEY` are set automatically when deployed via Supabase CLI.

## 3. Database migration

Run `supabase/migrations/009_subscriptions.sql` in the SQL Editor (or `supabase db push`).

## 4. Deploy Edge Functions

```bash
cd C:\care_bridge
supabase login
supabase link --project-ref YOUR_PROJECT_REF
supabase functions deploy create-checkout-session
supabase functions deploy verify-checkout-session
supabase functions deploy stripe-webhook
supabase functions deploy create-portal-session
```

## 5. Stripe webhook

1. Stripe → **Developers → Webhooks** → Add endpoint  
2. URL: `https://YOUR_PROJECT_REF.supabase.co/functions/v1/stripe-webhook`  
3. Events:
   - `checkout.session.completed`
   - `customer.subscription.created`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `invoice.paid`
   - `invoice.payment_failed`
4. Copy signing secret → `STRIPE_WEBHOOK_SECRET`

## 6. Redirect URLs

### Desktop (Windows/macOS/Linux)

- Stripe returns to `http://127.0.0.1:54722/?session_id=...`
- Ensure port **54722** is free (OAuth uses 54721).

### Mobile

Add to Stripe **allowed redirect URLs** (if prompted):

- `carebridge://subscription-success`
- `carebridge://subscription-cancel`

(Already configured in Android `AndroidManifest.xml`.)

## 7. Flutter dev flags

```bash
# Live Stripe (default)
flutter run -d windows

# Force simulated checkout (no Stripe)
flutter run -d windows --dart-define=STRIPE_ENABLED=false
```

## 8. Customer portal

Premium users can manage cards and cancel via **Stripe Customer Portal** (wired in app via `create-portal-session`).

Enable in Stripe → **Settings → Billing → Customer portal**.

## Money flow

```
User → Stripe Checkout → Your Stripe balance → Your bank account
```

Subscription state is synced by webhooks into `public.subscriptions` and `profiles.extras`.
