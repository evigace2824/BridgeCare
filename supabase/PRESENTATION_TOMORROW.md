# Presentation tomorrow — quick guide

Checkout **works now** without deploying Stripe Edge Functions.

## Demo flow (5 minutes)

1. Run the app: `cd C:\care_bridge` then `flutter run -d windows`
2. Log in as **Volunteer** or **Family**
3. Open **Premium** → tap **Subscribe**
4. Tap **Continue to Stripe** — if billing server is not deployed, you get **Stripe-style checkout** in-app
5. Enter test card: **4242 4242 4242 4242**, expiry **12/34**, CVC **123**, any name
6. Tap **Pay** → Premium unlocks
7. Open **Premium benefits** → **Manage subscription & payment method** → cancel or view card

## What to say in the presentation

> "Payments use Stripe in production. For this demo we use Stripe test cards with the same checkout UX; production connects to Supabase Edge Functions and real Stripe webhooks."

## Optional: real Stripe tonight

Follow `STRIPE_SETUP.md` and run with:

```powershell
flutter run -d windows --dart-define=STRIPE_LIVE=true
```

Then checkout opens the real Stripe website.

## Test cards

| Card | Result |
|------|--------|
| 4242 4242 4242 4242 | Success |
| 4000 0000 0000 0002 | Declined (for error demo) |
