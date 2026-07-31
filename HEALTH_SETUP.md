# Health Sync — Final Platform Setup

The app is now fully wired to read **Heart Rate, Blood Pressure, Steps, SpO₂, and Body Temperature** from the user's wearable via:

- **Android**: Google Health Connect
- **iOS**: Apple HealthKit

## Android (already done in code)

`android/app/src/main/AndroidManifest.xml` declares:

- `android.permission.health.READ_HEART_RATE`
- `android.permission.health.READ_BLOOD_PRESSURE`
- `android.permission.health.READ_STEPS`
- `android.permission.health.READ_OXYGEN_SATURATION`
- `android.permission.health.READ_BODY_TEMPERATURE`
- `android.permission.health.READ_SLEEP`

Plus Health Connect rationale `intent-filter` on `MainActivity` and a `<queries>` entry for `com.google.android.apps.healthdata`.

### Test on a real Android phone

1. Install **Health Connect** from Play Store (pre-installed on Android 14+).
2. Pair your watch and ensure it writes heart-rate / blood-pressure into Health Connect.
3. Open BridgeCare → Health → tap **Connect and sync**.
4. Toggle **Live sync (every 20s)** for real-time updates.

## iOS (one-time Xcode step)

Code & files already added:

- `ios/Runner/Runner.entitlements` (HealthKit entitlement)
- `ios/Runner/Info.plist` (Health/Microphone/Location/Camera usage descriptions and background modes)

### One-time Xcode action

1. Open `ios/Runner.xcworkspace` in Xcode.
2. Select the **Runner** target → **Signing & Capabilities**.
3. Click **+ Capability** → add **HealthKit**.
4. In the **Build Settings** (or Signing & Capabilities panel) confirm `Code Signing Entitlements` points to `Runner/Runner.entitlements`.
5. Build & run on a real iPhone (HealthKit isn't available in the simulator).

### Test on real iPhone

1. Open the **Health** app → Sharing → Apps → BridgeCare → enable Heart Rate / Blood Pressure / Steps / Oxygen / Body Temperature.
2. Open BridgeCare → Health → tap **Connect and sync**.
3. Toggle **Live sync (every 20s)**.

## What you should see

- Connection badge becomes **Connected**.
- Vitals grid populates: Heart, Blood pressure, Steps, Oxygen, Temperature.
- "Last synced …" updates after each sync.
- Abnormal heart-rate readings trigger a local push notification on the device.

## Why it doesn't work on Windows

Apple HealthKit and Health Connect are mobile-only frameworks. On desktop/web the wearable card will show "Not connected" and an explanatory hint. This is by design.
